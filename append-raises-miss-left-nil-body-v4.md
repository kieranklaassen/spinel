<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

An append to a String local that a builtin's miss left nil does nothing, and the read after it answers nil, where CRuby raises NoMethodError. The fix adds no nil test ahead of a call and nothing to the nil-target emitters (`emit_nil_target_stmt`, `emit_nil_target_call`): the test the append already makes of its handle raises. No append pays: by callgrind a `t << "a"` runs 16 instructions less with gcc and the same with clang.

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

The append tests its handle anyway. For an append to a local's handle that may be nil from a nil the fact cannot bound, `cplan_nil` now answers a new `CN_RAISE_IN_CALL`, and `str_mutate_append_bang_arms` (`src/codegen_stmt.c`) emits the statement's first link through `sp_String_append_recv` (new in `lib/spinel_rt.h`, with `sp_String_append_recv_n` for an interpolation's parts), whose NULL arm raises once the operand has run. `&.` and a guarded append keep their C. So does a program that gives nil an answer of its own: a method of the name or a `method_missing`, or either name spelled as a Symbol anywhere (an alias, `alias_method`, `define_method`, `send`), which `cplan_nil_program_answers` (`src/call_plan.c`) asks.

Cost, by callgrind on master 9c7ea3ce, before and after. 5,000,000 `t << "a"` on a slice's answer: 516,556,614 and 436,557,486 instructions with gcc, 16 an append less, 421,517,237 and 421,517,992 with clang, 755 more that are paid once a run. 2,000,000 `t << "a#{i}b"`: 713,499,806 and 527,490,652 with gcc, 686,200,191 and 686,200,960 with clang. On a String the method built (`t = +""`) the C is identical. `tools/cident.sh` on that master: 6,507 identical, 6 differ, 0 refusal changes, 0 refused by both, of 6,513: this test and five that append through a local holding an instance variable's String.

Not in this change, each silent on master too and left for a change of its own: a chained append on a local the program set to nil (`t = nil if c; t << "a" << "b"`), whose links the statement appends without asking the plan; and an append in the body of a loop that tests after it (`begin; t << "a"; end while t`), which the nil fact takes for guarded by the loop's condition.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run on this head on linux-x86_64 before opening: the new test with gcc and clang, with and without `--share-strings`, plain and under both GC stress modes; `ruby tools/gate.rb check`; `tools/cident.sh` against master 9c7ea3ce; `make nil-check-test`; `make share-strings-test`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (the tests have none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: nothing
