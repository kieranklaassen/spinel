<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

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

What it costs is such a call in code that never runs: master's C links there only where the C compiler drops the call. Of 44 never-run forms, 33 are right on master and refused now. 17 are written dead (`p wide(1) { |v| v + 1 } if false`, the call after a `return`). 16 are false by a value the C compiler follows, and do not look dead:

```ruby
def dbg? = false
p wide(1) { |v| v + 1 } if dbg?
```

and likewise a false or nil constant, local, global or instance variable, `n = 3; ... if n > 5`, `mode = :prod; ... if mode == :dev`, a `while` never entered and `0.times { ... }`. At `-O 0`, 19 of the 33 do not link on master with gcc or with clang, and 3 more not with clang. Master refuses each of the 33 today where the block answers nil (`p(wide(1) { |v| nil }) if dbg?`), with this message.

Tests: `test/reject/yielding_method_locals_past_inline_room.rb` is the program above, in `reject-test` and with its two records in `test/collect/refusals.expected`.

Generated C against master (`make cident REF=8578e3fb`): `6354 identical, 0 differ, 0 refusal changes`. `tools/refusals.sh` passes (536 records). optcarrot's generated C is byte-identical. Programs, with CRuby 3.3.6 as the reference: 1,222 chains of 3 to 300 methods, 277 programs with the call in the never-run forms, and 210 around one wide method. 113 whose C did not build or link on master are refused by name. 69 that are right on master are refused: the 33 forms above, with `wide` as written and with `block_given? ? yield(a127) : a127` as its last line, and 3 more. The other 1,527 are the same: 726 right, 447 refused, 278 wrong (the chains past 33 methods that answer nil) and 76 that do not build, most of them a call with no block, which is not a block-driving call.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (none: the new test is a reject test)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
