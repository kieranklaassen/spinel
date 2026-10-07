<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
T = [[1, 2], nil, [3]]
T[1] ||= []
p T[1]              # CRuby: []. master: [0, 0, 0, 0, 0, 0, 0, 0]
```

With `T[1] ||= {}` or `T[1] ||= 5` the read ends in SIGSEGV, and so does `T[0] &&= {}; p T[0]` over the row that is there.

The test for a constant table of Integer Arrays (`const_array_elems_all_int_array` in `src/analyze_infer.c`) reads the rows stored after the constant is written from `T[i] = v` and `T.store(i, v)`. `T[i] ||= v` and `T[i] &&= v` are nodes of their own and were not read, so the table stayed a table of Integer Arrays whatever they stored. A row of another kind stored that way makes it a general table now.

An Integer Array stored that way leaves a table of Integer Arrays one and does not make one: the rows of the literal and `T[i] = v` say that, as before. `T = [nil, nil]; T[1] ||= [7, 8]` stays a general table, whose `T[0]` is nil. So every table this changes goes from typed to general.

The cost: a table such a statement may give a row of another kind is read boxed from then on, also in a run where the store does not happen (`T[1] ||= []` over a row that is there), as master reads a table after `T[1] = [] if cond`.

Not in this change, and as on master: an empty row that is no bare literal. `T[1] ||= ([])` reads back as eight zeros, and `e = []; T[1] ||= e` answers 8 for `T[1].size`.

The test is `test/const_table_index_or_assign_row.rb`: 23 lines printed; master prints 3 of them and ends in SIGSEGV. `tools/cident.sh` against master 06064727 answers `6334 identical, 1 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`, the one being the test. optcarrot's C does not change.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; the first 16 lines were equal under Ruby 4.0.7, the 7 added since are not yet run there)
- [ ] Values past 2^31 are marked `# spinel: int64` (none in the test)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
