<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
D = [[1, 2], [3, 4]]
D << ["a"]
p D[2]              # CRuby: ["a"]. master: [0, 0, 0, 0]

E = [[1, 2], [3, 4]]
E << []
p E[2], E[2].size   # CRuby: [] and 0. master: [0, 0, 0, 0, 0, 0, 0, 0] and 8

F = [[1, 2], [3, 4]]
F.push({})
p F[2]              # CRuby: {}. master: SIGSEGV
```

The same with `append`, `unshift`, `prepend`, `insert` and `concat`, and after `D.fill(["x"])`, `D.replace([["a"]])` and `D.map! { |r| r.reverse }`, where `p D[0]` prints [0, 1, 0, 0, 0, 0, 0, 0].

The test for a constant table of Integer Arrays (`const_array_elems_all_int_array` in `src/analyze_infer.c`) read the rows stored after the constant is written from `T[i] = v` and `T.store(i, v)` alone. Its twin for an instance variable reads the push family, `insert` and `concat` too. A row pushed onto a constant was not read, the table stayed a table of Integer Arrays whatever was pushed, and `T[i]` read the pushed row as an `sp_IntArray` without a test.

The loop that reads a row-storing call is one function now (`an_stored_rows_int`), asked by both tests. For a constant, a row of another kind stored by any of these calls makes the table a general one. So do `map!` and `collect!`, and `fill` and `replace` unless they hand over Integer Arrays and nothing else. A row stored this way never makes a table a table of Integer Arrays: the rows of the literal and `T[i] = v` say that, as before, so `T = []; T << [7, 8]` stays a general table. Every table this changes goes from typed to general.

That is the cost too: a table given a row through a local or a splat (`x = [[7, 8]]; D.concat(x)`), one whose rows `map!` writes anew, and one with a push of another kind that never runs (`D.push(["a"]) if cond`) are read boxed from then on, as master reads a table after `D[1] = [] if cond`.

Not in this change, and the same before and after it: a table appended to through another name (`t = D; t << ["a"]`) or by a method it is handed to, a store chained on another's answer (`D.push([5]).push(["a"])`), and an empty row written in parentheses (`D << ([])` reads back as eight zeros, `D.push(({}))` crashes).

The test is `test/const_table_pushed_row.rb`: 44 lines printed, 14 differ on master. `tools/cident.sh` against master 06064727 answers `6334 identical, 1 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`, the one being the test. optcarrot's C does not change.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; the first 27 lines were equal under Ruby 4.0.7, the 17 added since are not yet run there)
- [ ] Values past 2^31 are marked `# spinel: int64` (none in the test)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
