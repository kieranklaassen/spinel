<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
p [1, 5, 2, 8, 3].lazy.map { |x| next 0 if x > 3; x * 2 }.to_a
# CRuby: [2, 0, 4, 0, 6]. master: [2, 4, 6]
p [1, 2, 3].lazy.map { |x| y ||= x; y }.to_a
# CRuby: [1, 2, 3]. master: [1, 1, 1]
```

The same in `select`, `reject`, `filter_map`, `flat_map`, `take_while` and `drop_while`, and a `redo` in such a block was refused.

The cost: a block with a `next` or a `redo` that master already ran right pays the step's frame, 3 instructions an element (`map { |x| next 0 if x < 0; x * 2 }` over 200,000 Integers, ten times: 216,204,165 to 222,204,036), 9 with a local in a `select` (`select { |x| next if x < 0; z = x % 3; z == 0 }`: 215,563,059 to 233,563,128). A block whose local is first assigned under a condition pays its reset, 4 an element (`map { |x| if x >= 0; y = x + 1; end; y * 2 }`: 316,206,481 to 324,206,481).

`emit_lazy_pipeline_expr` (`src/codegen_call.c`) writes every stage of the pipeline into one C `for`. It wrote a block's leading statements straight into that loop and read the last one as the answer. So a `next` was the loop's own `continue`: the element was dropped and the value never read. Under a `begin` that `next` also popped the rescue's frame, as a `next` that leaves the `begin` does, and a raise after the pipeline went uncaught. Nothing reset the block's locals between elements, and a `redo` had no label to go to.

A stage now opens its block with `emit_iter_step_open` and reads the answer through `emit_iter_step_tail` or `emit_iter_step_cond`, as the other builtin iterators do, where the step has work for them (`lazy_block_wants_step`): a `next` or a `redo` of the block's own, or a local that has to be fresh for every element. That is a local a closure holds, or one the block does not assign at its top level, alone or in a multiple assignment, before anything names it. Any other block emits the C it did: `map { |x| y = x + 1; y * 2 }` writes `y` anew for every element and needs no reset.

A block with a `break` anywhere in it is read as it was, whole (`lazy_block_plain`): a `break` of its own, wherever it is written, and a nested block's or loop's too. In the step's frame the block's `break` would leave only the frame, and the stage would go on with nil where the block raises LocalJumpError; the `break` of a pipeline written inside the block has no loop of its own to leave and went the same way. Only a lambda and a method definition are not looked into. So in such a block a `next` still drops the element and, under a `begin`, the rescue's frame; the locals are not reset; and a `redo` is still refused.

A `redo` is also still refused where the stage would answer wrongly with it: in `find_all`, which answers nil here with or without it; in a `drop_while` block of more than one parameter, whose branch binds the first alone; and in a block with a destructured parameter (`|(a, b), c|`), which the redo would bind again.

Of 9,383 generated programs, run on master 8dc55225 (a `next` written ten ways in nine stages over five kinds of source, alone and in the middle of a chain; block-locals written 7 ways and then 16; parameter lists; a `redo` alone and under eleven parameter lists; a `break` written eleven ways in the block and in twelve places around it, firing and never firing, beside a `next`, a `redo` or a `next` under a `begin`), 2,523 that were wrong are right and 460 that were refused are right. 1,711 are right before and after with the stage opened the new way, at the cost above, and 4,495 emit master's C. 140 raise as they did on master, by `drop_while`'s one bound parameter. 54 that were refused do not build, by the unread keyword, as they do not on master with the `redo` out. None that is right on master is wrong, refused or not building. The 4,505 of them also run with `--share-strings` answer the same there.

Not here, each as on master: `drop_while` still binds its first block parameter alone, so `{ |x, y| y < 4 }` over pairs raises; a block with a keyword it never reads does not build, in every stage but `drop_while`; over `each_with_index` a block of one parameter is handed the pair once another stage stands before it (`.select { |x| true }.map { |x| x }` answers `[[4, 0], [7, 1]]` for `[4, 7]`); after a stage with a `redo`, `include?` runs every element, as it does without the redo; and a `break` in a `while`'s condition raises LocalJumpError where CRuby leaves the loop.

`docs/limitations.md` says where a `redo` in a lazy stage is still refused. `test/reject/redo_unlabeled_iterator.rb` keeps its line and takes a stage's block that holds a `break`; `make reject-test` and `tools/refusals.sh` pass, and `test/collect/refusals.expected` does not change.

The tests are `test/lazy_stage_step_frame.rb` (31 lines printed; master refuses it at its first `redo` line and, with the three `redo` lines out, has 17 of the other 28 wrong and stops before the last 5, at the raise the `next` left uncaught), and six that end in the LocalJumpError of a `break` beside a `next` and pass on master too: `test/lazy_stage_break_beside_next.rb`, `test/lazy_drop_while_break_beside_next.rb`, and `test/lazy_stage_break_in_receiver_beside_next.rb`, `..._in_argument_...`, `..._in_for_...` and `..._in_pipeline_...` for a `break` in the receiver and in an argument of a call that takes a block, in a `for`'s collection and in a pipeline inside the block. `tools/cident.sh` against master 8dc55225 answers `6452 identical, 0 differ, 1 refusal changes, 0 refused by both, 0 not in the reference`: the one is the first test, no longer refused. optcarrot's C does not change.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; not yet run under Ruby 4.0)
- [ ] Values past 2^31 are marked `# spinel: int64` (none in the tests)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
