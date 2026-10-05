<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
[[1, 2], [], [3, 4]].each { |a, b| p [a, b] }
# CRuby: [1, 2] [nil, nil] [3, 4]. Here: [1, 2] [0, 0] [3, 4]

[[1, 2], [], [3, 4]].each { |a, b| next if a.nil?; p a * b }   # CRuby: 2 12. Here: 2 0 12
[[1, 2], [], [3, 4]].each { |a, b| v = a || 7; p v + 1 }       # CRuby: 2 8 4. Here: 2 1 4
[[1.5, 2.5], []].each { |a, b| p a.to_f + 1 }                  # CRuby: 2.5 1.0. Here: 2.5 nil
[[1, 2], {}, [3, 4]].each { |a, b| p [a, b] }                  # here: a crash
```

Nothing is said. `reverse_each`, `each_entry`, three parameters and `_1`, `_2` do the same.

`each` with two or more block parameters on a literal types them from the rows: it unifies the rows' types and gives the parameters the element type they share (`infer_block_params_container_arms` in `src/analyze_pass.c`). An empty `[]` row has no type to unify, so it dropped out, the parameters were typed Integer, and the loop read every row out of the boxed table as an `sp_IntArray` without a test. The empty row is built as a poly array, and read through the other struct it has a length of 8 and the poly array's storage as its elements. A bare `Array.new` row went the same way.

An empty container among the rows now counts as the boxed value it is built as, the way the Array literal itself already counts it when it types the table. The parameters are then general values and the loop spreads each row by its kind, as it does for a table with a nil or a mixed row. One loop changes, by one condition.

**Measured against master 701529f0, each program compared with CRuby 3.3.6.** 7,260 generated programs, each a different one: a table of rows (Integer, Float, String, Symbol, mixed, with nil, with a literal past 64 bits, of two lengths) with an empty row nowhere, first, in the middle, last, twice, alone, or written `Array.new` or `{}`; held as the literal, the literal in parentheses, in a local, in a parameter; under 33 blocks (`each` with two and three parameters, `_1` and `_2`, a default, a splat, `|(a, b)|`, one parameter; `reverse_each`, `each_entry`, `map`, `filter_map`, `select`, `reject`, `any?`, `all?`, `count`, `find`, `flat_map`, `group_by`, `partition`, `sort_by`, `min_by`, `each_with_index`, `each_with_object`, `for a, b in`).

| | master 701529f0 | this branch |
|---|---|---|
| 6,478 programs | | generated C identical to master's |
| 782 programs (the literal with Integer, Float or String rows and an empty row) | 452 as CRuby, 274 wrong and silent, 48 crash, 8 raise TypeError | 782 as CRuby |

No program that answered as CRuby on master answers differently. The crashes and the TypeError ("can't convert Hash into Float") are the `{}` row. A table held in a local or a parameter, and a table with a row holding a literal past 64 bits, were right and are unchanged.

**The cost.** Over a literal with an empty row the parameters are general values from now on, also in a program that was right on master (the 452 above). `[[1, 2], [], [3, 4]].each { |a, b| total += a + b if a }` run 3,000,000 times takes 0.27 s on master and 0.32 s here, 1.2 times (gcc 13.3, best of five). A literal with no empty row is untouched, its C identical.

Not in this change: an empty row written in parentheses, `[[1, 2], ([]), [3, 4]].each { |a, b| ... }`, binds 0 and 0 on master and still does. The same row in a table held in a constant or an instance variable (`T = [[1, 2], []]; T.each { |a, b| ... }`, `T[1]`) is decided elsewhere and is a separate change.

**Generated C.** `tools/cident.sh` against 701529f0: `5924 identical, 0 differ, 0 refusal changes, 0 refused by both, 1 not in the reference` (the new test). No test's, no benchmark's and not optcarrot's C changes. Compared again on master 92510d6c1 together with the sibling change to constant and ivar tables: of 6,017 programs only the two new tests differ.

**Test.** `test/each_params_literal_empty_row.rb` (38 lines printed; master crashes on the `{}` line, and without it 11 of 35 differ). It prints the same under `SPINEL_GC_STRESS=1` and `2`.

The `.expected` file is from CRuby 3.3.6 run with `--enable-frozen-string-literal`; 4.0 is not installed where this was written.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; the test prints Integers, Floats, Arrays, a Hash, nil and booleans)
- [ ] Values past 2^31 are marked `# spinel: int64` (none in the test)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
