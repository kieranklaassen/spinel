<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
p [1, 5, 2, 8, 3].lazy.map { |x| next 0 if x > 3; x * 2 }.to_a
# CRuby: [2, 0, 4, 0, 6]. master: [2, 4, 6]
p [1, 2, 3].lazy.map { |x| y ||= x; y }.to_a
# CRuby: [1, 2, 3]. master: [1, 1, 1]
```

The same in `select`, `reject`, `filter_map`, `flat_map`, `take_while` and `drop_while`, and a `redo` in such a block was refused.

`emit_lazy_pipeline_expr` (`src/codegen_call.c`) writes every stage of the pipeline into one C `for`. It wrote a block's leading statements straight into that loop and read the last one as the answer. So a `next` was the loop's own `continue`: the element was dropped and the value never read. Nothing reset the block's locals between elements, and a `redo` had no label to go to.

Each stage now opens its block with `emit_iter_step_open` and reads the answer through `emit_iter_step_tail` or `emit_iter_step_cond`, as the other builtin iterators do. A block with no `next`, no `redo` and no local of its own emits the C it did.

Of 4,515 generated programs (a `next` written ten ways in nine stages, over Arrays of Integers and of Strings, a Range, a Hash and `each_with_index`, first, in the middle and last in a chain; block-locals; parameter lists; `redo`), 2,023 that were silently wrong are right and 27 that were refused are right. 1,649 are right before and after, 660 emit master's C, and none that is right on master is wrong, refused or not building. The 1,815 of them also run with `--share-strings` answer the same there.

Not here, each as on master: `drop_while` still binds its first block parameter alone, so `{ |x, y| y < 4 }` over pairs raises (140 of the programs); and in a block of two parameters a local assigned `x.odd? && x` reads `true` for the value (11; the `next` beside it is cured).

`redo` is still refused in the block of `chunk_while`, `slice_when`, `transform_values` and `Array.new`, whose emitters place no label. `test/reject/redo_unlabeled_iterator.rb` moves to `chunk_while`, and `docs/limitations.md` takes the lazy stages out of that row. `make reject-test` and `tools/refusals.sh` pass; `test/collect/refusals.expected` does not change (the refusal is at the same line of the same file).

The test is `test/lazy_stage_step_frame.rb` (19 lines printed; master refuses it at its `redo` line and, with that line out, differs on 13 of the other 18). `tools/cident.sh` against master a2bd8900 answers `6374 identical, 1 differ, 1 refusal changes, 0 refused by both, 0 not in the reference`: `test/lazy_method_block_local.rb` gains the reset of its block-locals, and the new test is no longer refused. optcarrot's C does not change.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; not yet run under Ruby 4.0)
- [ ] Values past 2^31 are marked `# spinel: int64` (none in the tests)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
