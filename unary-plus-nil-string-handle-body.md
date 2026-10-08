<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`+t` on a String local the program set to nil answers nil where its value is written to another local, and CRuby raises NoMethodError. The fix adds nothing to the codegen nil helpers (`emit_nil_target_stmt`, `emit_nil_target_call`): the test is written at the two places that emit the call, as the statement expression the `--share-strings` route already writes there. A `+t` on a local that is never nil compiles to the same C, and one that may be nil pays nothing a call by callgrind.

```ruby
def f(c)
  t = +""
  t << "4"
  t << "2"
  t = nil if c
  x = +t
  x << "!"
  p x
end
f(true)    # master: nil. CRuby: NoMethodError
```

Two appends make `t` an `sp_String` handle, and nil is a NULL handle. In the default build `emit_strbuf_value` (`src/codegen_stmt.c`) hands the slot to `sp_String_uplus` with no test, and `emit_multi_write_stmt` does the same for `x, n = +t, 1` in every build; `sp_String_uplus` answers a NULL handle as it is, so `x` is nil and the appends after it do nothing. An arm of a conditional (`x = c ? +t : u`) reaches the first of the two.

Both now go through `emit_strbuf_uplus`, which tests the handle first where the nil fact says the operand may be nil, as `emit_strbuf_route` does under `--share-strings`, and keeps the bare call for one that is never nil. A program that gives nil an answer to `+@` itself keeps its C too: a method of that name or a `method_missing`, or either name spelled as a Symbol anywhere (an alias, `alias_method`, `define_method`, `send`), which `cplan_nil_program_answers` (`src/call_plan.c`) asks.

Depends on the pull request "An append raises on a String local that a builtin's miss left nil": `cplan_nil_program_answers` comes from it, and this is one commit on top of it.

Cost, by callgrind, the commit under this one and this one. 5,000,000 `x = +t` on a local that may be nil: 30,666,679 and 30,666,680 instructions with gcc, 50,626,611 and 50,626,641 with clang, 1 and 30 more for the whole run; under `--share-strings` the C is identical. 5,000,000 `x, n = +t, 1`: 1 more with gcc and 12 with clang for the run, in both builds. On a local that is never nil the C is identical. `tools/cident.sh` against the commit under this one: 6,513 identical, 1 differ (this test), 0 refusal changes, 0 refused by both, of 6,514.

Not in this change: in the default build a String local read before any write (`(t = +"a"; t << "b") if c; x = +t`) has no nil fact, and its `+t` answers nil as on master; `--share-strings` raises there already.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run on this head on linux-x86_64 before opening: the new test with gcc and clang, with and without `--share-strings`, plain and under both GC stress modes; `ruby tools/gate.rb check`; `tools/cident.sh` against the commit under this one; `make nil-check-test`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (the tests have none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [x] Depends on: the pull request "An append raises on a String local that a builtin's miss left nil"
