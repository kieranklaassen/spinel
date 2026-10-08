<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Held, not for opening while upstream's issue on the codegen nil helpers (issue 7444) is open: this change is a nil test ahead of a call, in a wrapper around the append.

An append to a String local that a slice past the end or an element read left nil does nothing, and the read after it answers nil, where CRuby raises NoMethodError. The fix tests the handle in a wrapper around the append (`sp_String_append_recv`) and adds nothing to the nil-target emitters (`emit_nil_target_stmt`, `emit_nil_target_call`). An append at such a site pays about 2 instructions where the program appends to any other String.

```ruby
def tail(s)
  t = s[10, 2]
  t << "a"
  t << "b"
  t
end
p tail("abc")    # master: nil. CRuby: NoMethodError
```

Two appends make `t` an `sp_String` handle, and the slice past the end left it NULL. `cplan_nil` (`src/call_plan.c`) plans a nil test ahead of a call only for a nil the program writes, so that a receiver that is never nil does not pay for one. A builtin's answer is not such a nil: the append ran on the NULL handle, `sp_String_append_bin` did nothing there, and the read answered nil. An element read (`a[5]`), a match that fails (`s[/x+/]`), `concat`, an interpolation and an append that is its method's value went the same way.

The change covers a miss whose answer carries a nil fact: a String's slice or index (`s[10, 2]`, `s[10..]`, `s[10]`, `s[/x+/]`, `s["zz"]`, `slice`, `byteslice`), a capture (`$1`), an Array's `pop`, `shift`, `max`, `min`, `sample` and `dig`, a Hash's `delete`, `dig` and `fetch(k, nil)`, and an element of an Array a parameter or a builtin holds (`a[5]`, `s.chars[9]`, `ARGV[7]`). For such an append as a statement, `cplan_nil` now answers a new `CN_RAISE_IN_CALL`, and `str_mutate_append_bang_arms` (`src/codegen_stmt.c`) emits the statement's first link through `sp_String_append_recv` (new in `lib/spinel_rt.h`, with `sp_String_append_recv_n` for an interpolation's parts): it tests the handle once the operand has run, raises for NULL, and calls `sp_String_append_bin`, which tests the handle again. `&.` and a guarded append keep their C. So does a program that gives nil an answer of its own: a method of the name or a `method_missing`, or either name spelled as a Symbol anywhere (an alias, `alias_method`, `define_method`, `send`). `cplan_nil_program_answers` (`src/call_plan.c`) walks the program's Symbols for that and keeps its answer for a name: 8,000 such appends beside 8,000 Symbols compile in 1.19 s, master's 1.17.

Cost, by callgrind on master 9c7ea3ce, gcc and clang, over 1,000,000 calls of a method of two such statements in a program that appends to another String elsewhere: `t << "a"` 2.0 and 2.2 instructions an append; `t << a[i % 3]` 2.0 and 1.3; `t << v` with `t.concat(v)` 2.0 and 0.6; `t << "a" << "b"` 2.6 and 0.8 a statement; `t << "a#{i}b"` 0.6 more and 2.4 less. `sp_String_append_bin` is called out of line there, and the wrapper's test runs ahead of the one it makes. Where the two `t << "a"` are the program's only appends, gcc inlines the append into the wrapper and runs 19.2 instructions an append less, an accident of its inliner; clang's count is master's. On a String the method built (`t = +""`) the C is identical. `tools/cident.sh` on that master: 6,507 identical, 6 differ, 0 refusal changes, 0 refused by both, of 6,513: this test and five that append through a local holding an instance variable's String.

Not in this change, each the same on master:

- A miss whose answer carries no nil fact stays silent: a bang method that answers nil (`strip!`, `chomp!`, `sub!`, `gsub!`, `tr!`, `squeeze!`, `downcase!` and their kin), `ENV` of a missing name, `gets` and `read` at the end of input, a MatchData's missing group (`m[2]`, `m[:n]`), `StringScanner#scan`, a lambda's nil, a Struct member set to nil.
- An append in value position: `x = (t << "a")` stays silent; `return t << "a"`, an argument, a condition and an interpolation crash.
- Operands: `t << 65` on the nil handle crashes (the Integer's conversion reads the handle ahead of the call), `t << nil` raises TypeError, `t.concat("a", "b")` raises FrozenError.
- A multiple assignment's target (`t, u = s[10, 2], 1`) stays silent.
- Two chained appends on a local the program set to nil (`t = nil if c; t << "a" << "b"; t << "c" << "d"`) stay silent: the statement plans its nil test for the link under it, not for the local.
- An append in the body of a loop that tests after it (`begin; t << "a"; end while t`) stays silent: the nil fact takes it for guarded by the loop's condition.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run on this head on linux-x86_64: the new test with gcc and clang, with and without `--share-strings`, plain and under both GC stress modes; `ruby tools/gate.rb check`; `tools/cident.sh` against master 9c7ea3ce; `make nil-check-test`; `make share-strings-test`; `make int-min-test`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (the tests have none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: nothing
