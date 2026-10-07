<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
p [1, 5, 2, 8, 3].lazy.map { |x| next 0 if x > 3; x * 2 }.to_a
# CRuby: [2, 0, 4, 0, 6]. master: [2, 4, 6]
p [1, 2, 3].lazy.map { |x| y ||= x; y }.to_a
# CRuby: [1, 2, 3]. master: [1, 1, 1]
```

The same in `select`, `reject`, `filter_map`, `flat_map`, `take_while` and `drop_while`, and a `redo` in such a block was refused.

The cost: a block with a local of its own that master already ran right pays the reset every eager iterator's block already pays, 2 instructions a local for each element (`map { |x| y = x + 1; y * 2 }.select { |x| z = x % 3; z == 0 }` over 200,000 Integers, ten times: 399,562,760 to 407,562,815).

`emit_lazy_pipeline_expr` (`src/codegen_call.c`) writes every stage of the pipeline into one C `for`. It wrote a block's leading statements straight into that loop and read the last one as the answer. So a `next` was the loop's own `continue`: the element was dropped and the value never read. Under a `begin` that `next` also popped the rescue's frame, as a `next` that leaves the `begin` does, and a raise after the pipeline went uncaught. Nothing reset the block's locals between elements, and a `redo` had no label to go to.

Each stage now opens its block with `emit_iter_step_open` and reads the answer through `emit_iter_step_tail` or `emit_iter_step_cond`, as the other builtin iterators do. A block with no `next`, no `redo` and no local of its own emits the C it did. A parameter the block assigns is such a local: `{ |x| x = x + 1; x }` gains the reset of `x`.

A block that holds a `break` is read as it was, whole (`lazy_block_plain`). In the step's frame the `break` would leave only the frame, and the stage would go on with nil where the block raises LocalJumpError. So in such a block a `next` still drops the element and, under a `begin`, the rescue's frame; the locals are not reset; and a `redo` is still refused.

A `redo` is also still refused where the stage would answer wrongly with it: in `find_all`, which answers nil here with or without it; in a `drop_while` block of more than one parameter, whose branch binds the first alone; and in a block with a destructured parameter (`|(a, b), c|`), which the redo would bind again.

Of 5,217 generated programs (a `next` written ten ways in nine stages over Arrays of Integers and of Strings, a Range, a Hash and `each_with_index`, alone and in the middle of a chain; block-locals; parameter lists; a `redo` under eleven parameter lists; a `break`; a `next` under a `begin`), 1,218 that were wrong are right, 162 of them the uncaught raise after a `next` under a `begin`, and 220 that were refused are right. 598 are right before and after and 2,993 emit master's C. 132 are wrong or raise as they did on master, by `find_all` and the faults under "Not here" (12 of them read `find_all` for its value under a `begin`: nil as before, and the raise after it is now rescued). The refusal stood in front of two of those faults. 54 that were refused do not build, by the unread keyword, as they do not on master with the `redo` out. 2 that were refused are wrong, by the boxed local: `filter_map { |k, v| u = v.odd? && v; unless done; done = true; redo; end; u }` over `{ a: 1, b: 4, c: 5 }` answers `[true, true]` for `[1, 5]`, the line master prints for it with the `redo` out, and so does the same block with `|x = 7|` over `[1, 2, 3]`. None that is right on master is wrong, refused or not building. The 2,127 of them also run with `--share-strings` answer the same there.

Not here, each as on master: `drop_while` still binds its first block parameter alone, so `{ |x, y| y < 4 }` over pairs raises; where a block's parameters are boxed (two of them, or an optional one), a local assigned `x.odd? && x` reads `true` for the value; a block with a keyword it never reads does not build, in every stage but `drop_while`; over `each_with_index` a block of one parameter is handed the pair (`map { |x| x }` answers `[[4, 0], [7, 1]]` for `[4, 7]`); and after a stage with a `redo`, `include?` runs every element, as it does without the redo.

`docs/limitations.md` says where a `redo` in a lazy stage is still refused. `test/reject/redo_unlabeled_iterator.rb` keeps its line and takes a stage's block that holds a `break`; `make reject-test` and `tools/refusals.sh` pass, and `test/collect/refusals.expected` does not change.

The tests are `test/lazy_stage_step_frame.rb` (27 lines printed; master refuses it at its first `redo` line and, with the three `redo` lines out, differs on 16 of the other 24), and `test/lazy_stage_break_beside_next.rb` and `test/lazy_drop_while_break_beside_next.rb`, which end in the LocalJumpError of a `break` beside a `next` and pass on master too. `tools/cident.sh` against master 5c78f07e answers `6414 identical, 1 differ, 1 refusal changes, 0 refused by both, 0 not in the reference`: `test/lazy_method_block_local.rb` gains the reset of its block-locals, and the new test is no longer refused. optcarrot's C does not change.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; not yet run under Ruby 4.0)
- [ ] Values past 2^31 are marked `# spinel: int64` (none in the tests)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
