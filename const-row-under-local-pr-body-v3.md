<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
T = [[1, 2], [3, 4]]
e = T[1]
e << "s"
p e, T[1]
# CRuby: [3, 4, "s"] twice. master: [3, 4, "s"] and [3, 4]
```

The same with `e[0] = "s"`, `e.insert(1, :s)`, `e.unshift("s")` and `e.concat(["s"])`, with a Float, a Symbol or nil for the String, and with the row read by `T.first`, `T.last` or `T.at(1)`.

The cost: such a table is read boxed, whether or not the store runs. Beside `e = T[1]; e << "s" if ARGV.size > 5`, a million rounds of `s += T[0][i & 3] + T[i & 1][0]` go from 44,663,935 instructions to 105,675,251, about 30 a read with gcc. A walk of the rows is cheaper than it was: `T.each { |r| t += r[0] + r[3] }` over three rows, 946 instructions a walk to 307. The test cannot be narrower than the store being written: master already reads the local as a general Array because of that store, run or not, and the row is what the local is.

`const_array_elems_all_int_array` (`src/analyze_infer.c`) answers that the table's rows are Integer Arrays. The push widens the local to a general Array, and the read then converts the row: the local held a copy, and the table kept the row as it was.

Where the table is one literal of Integer Array literals that nothing stores a row into, and a local bound to one of its rows is given an element that is no Integer, the answer is now no (`const_row_local_widened`). The rows are then built as general Arrays, as they are when the element is given through the table (`T[1] << "s"`), and the local reads the row itself. The locals that hold a row and the stores made through them are listed once a pass (`row_stores_build`), and the question is a scan of that list: 4,000 locals `e = T[i]; p e[0]` go through `spinel -S` in 7.0 s where master takes 7.3, and 2,000 locals with an Integer pushed through each in 1.2 s where master takes 1.3.

Every other table keeps its answer and its C: one made by `map`, `Array.new` or `times`, a frozen one, one with a row stored into it or written twice. Their rows are not rebuilt by the literal walk, and with the answer no the push would raise a TypeError there. So would a value of two kinds (`e << (c ? "s" : 1)`), which rebuilds no literal, and it is left as it was. Under `--share-strings` a `concat` is left as it was too: with the rows general Arrays the flag refuses the String literal handed to it once the table is walked (`T.each { |a, b| ... }`).

Of 6,420 generated programs, run on master 8dc55225 (the store written 32 ways and its effect read 8 ways, 68 other reads of the table, 18 ways to make the table; at the top level, in a method, a block, a lambda and a class), without the flag 2,124 that were wrong are right, and 60 that answered where CRuby raises now raise as it does (`p T.map(&:max).max` after `e << "s"` printed 6). 1,323 are right before and after, 2,819 emit the C they did, and none that is right on master is wrong, refused or not building. With `--share-strings` the same counts are 2,098, 60, 1,308 and 2,860. The other 94 differ before and after from CRuby 3.3.6 for a reason of their own: 54 print a Hash, which 3.3.6 writes the old way, and 40 call `e.store`, which CRuby has no Array method for.

Not here, each a copy before and after: the row through a second local (`f = e; f << "s"`), a frozen table or one made by `map`, a table held in an instance variable, a value of two kinds, and under the flag the `concat`.

The tests are `test/const_table_row_under_local.rb` (42 lines printed, 15 differ on master; its last block is the value of two kinds, as on master) and, for the flag, `test/share/share_strings_const_row_concat.rb` (4 lines; it passes on master too, and is refused with the `concat` counted). `tools/cident.sh` against the change below this one answers `6448 identical, 1 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`, the one being the first test (the corpus does not read `test/share/`). `make share-strings-test` passes. optcarrot's C does not change.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; not yet run under Ruby 4.0)
- [ ] Values past 2^31 are marked `# spinel: int64` (none in the tests)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [x] Depends on: # (the change "A store chained on another's answer stores a row into a constant table too": this branch is that one's two commits and one more)
