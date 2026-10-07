<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
puts [1, 2, 4, 9].slice_when { |x, y| y - x - 1 }.to_a.inspect
# CRuby: [[1], [2], [4], [9]]. master: [[1, 2], [4], [9]]
```

An Integer is true, and so is 0. A Float went the same way, and the program's first Symbol; `(y - x) > 1 ? nil : 0` cut where it answered nil; and a block ending in `c && y` or `c || nil` did not build.

The slice_when arm of `emit_slice_when_chunk_inspect_expr` (`src/codegen_fold.c`), which serves `slice_when { }.to_a.inspect` over an Integer Array or Range, wrote the block's last statement with `emit_expr` into a C `if`. So the value was tested by C's truth: 0, 0.0 and the Symbol numbered 0 were false, nil's sentinel was true, and a boxed value was a struct in a condition. It is now written with `emit_cond`, as `emit_chunk_while_expr` writes it for `.to_a` alone. That one word is the change.

A block ending in a comparison or a predicate emits the C it did.

Of 1,152 generated programs, run on master 759d120f (24 block values over an Integer Array, a Range, a filtered Array and a Float Array, read six ways, at the top level and in a method), 263 that were wrong are right and 120 that did not build are right. 157 are right before and after with the test written the new way: a block answering `nil`, `1` or a String, and rows of `<=>`, `max` and a Symbol that the data had right. 612 emit master's C. None of them that is right on master is wrong or not building, and all 1,152 answer the same with `--share-strings`. The new test costs nothing where master was right: `slice_when { |x, y| nil }` over 200,000 Integers, ten times, is 994,287,593 instructions before and 994,287,579 after.

Not here: a block whose value is the Integer -9223372036854775808 now reads as nil, and its runs are not cut (`slice_when { |x, y| -9223372036854775807 - 1 }.to_a.inspect` printed `[[1], [2], [4], [9]]` and prints `[[1, 2, 4, 9]]`; none of the programs above has it). That Integer is what nil is kept as in an Integer's place, and master reads it as nil in `chunk_while`, in `select`, in `m ? 1 : 2` and in this same `slice_when` read by `p` or by `.to_a.length`. And, each as on master: a `next` with a value in this block is still the walk's own `continue` (`next true if y == x + 1; false` prints one run), and `slice_when { }.inspect` with no `to_a` between prints the runs where CRuby prints an Enumerator.

The test is `test/slice_when_inspect_block_truth.rb` (14 lines; master does not build it and, line by line, 9 are wrong, 2 do not build and 3 are right). Merged into master 8dc55225, `tools/cident.sh` against that master answers `6446 identical, 1 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`: the one is the new test. optcarrot's C does not change.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; not yet run under Ruby 4.0)
- [ ] Values past 2^31 are marked `# spinel: int64` (none in the test)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
