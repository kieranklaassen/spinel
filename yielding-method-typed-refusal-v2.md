<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A refusal with a cost, which is yours to weigh: a program that has such a call in code that never runs was right on master where the C compiler dropped the call, and is refused now. Of 2,040 programs measured with the call in a place that never runs, 1,785 are newly refused: 555 did not build on master, and 1,230 were right there.

```ruby
def wide(x)
  a1 = x
  # ... 127 locals in all
  yield a127
end
p wide(1) { |v| v + 1 }   # 2 in CRuby; C that does not build on master
```

A method that yields has no function of its own. Each call is written out in place, its locals renamed through a table of 128 names (`MAX_RENAME`), and with 128 names to add the inliner declines the call. `emit_inline_expr` refused such a call by name only where its value has no scalar type; where it has one the plain call to `sp_wide` was emitted, which nothing defines. The refusal now covers both:

```
a block-driving call to a method that yields could not be inlined (a yielding method has no standalone function to call)
```

The same table runs out along a chain of yielding methods whose blocks yield on, each written out inside the one before: 26 methods of four parameters did not link either and are refused. The table is not changed, and `docs/limitations.md` has the row.

The cost in full. Master's C links there only where the C compiler drops the call, and the 1,230 are in 26 never-run forms. Some are written dead (`p wide(1) { |v| v + 1 } if false`, the call after a `return`). Others are false by a value the C compiler follows, and do not look dead:

```ruby
def dbg? = false
p wide(1) { |v| v + 1 } if dbg?
```

and likewise a false or nil constant, local, global or instance variable, `n = 3; ... if n > 5`, `mode = :prod; ... if mode == :dev`, a `while` never entered and `0.times { ... }`. Master's rightness there is the C optimiser's: at `-O 0` with gcc, 96 of 154 of them sampled do not link on master. Master refuses each of them today where the block answers nil (`p(wide(1) { |v| nil }) if dbg?`), with this message.

What was chosen: a bare call inside `instance_exec` or `instance_eval` is left as it was. There a method that a subclass of the receiver overrides is declined for the class switch, the plain call links, and it is right.

Tests: `test/reject/yielding_method_locals_past_inline_room.rb` is the program above, in `reject-test` and with its two records in `test/collect/refusals.expected`. `test/instance_exec_overridden_yield.rb` has the calls inside `instance_exec` and `instance_eval`, right on master and here.

Generated C against master (`make cident REF=4f8b737c`): `6408 identical, 0 differ, 0 refusal changes` (the new test's C is master's). `tools/refusals.sh` passes (538 records). optcarrot's generated C is byte-identical. Programs of ours, on master 8578e3fb with CRuby 3.3.6 as the reference: 1,222 chains of 3 to 300 methods, 277 programs with the call in never-run forms, and 210 around one wide method. 113 whose C did not build or link on master are refused by name. 69 that are right on master are refused, all in never-run forms. The other 1,527 are the same: 726 right, 447 refused, 278 wrong (the chains past 33 methods that answer nil) and 76 that do not build, most of them a call with no block, which is not a block-driving call.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; the test prints Integers, a String, true and an Array)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
