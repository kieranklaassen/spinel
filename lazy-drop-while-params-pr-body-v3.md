<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
p [[1, 2], [3, 9], [5, 1]].lazy.drop_while { |x, y| y < 4 }.to_a
# CRuby: [[3, 9], [5, 1]]. master: undefined method '<' for nil (NoMethodError)
p [1, [3, 4], 5].lazy.drop_while { |x, y = 9| y == 9 }.to_a
# CRuby: [[3, 4], 5]. master: [1, [3, 4], 5]
```

`{ |*r| ... }` and `{ |*r, z| ... }` did not build.

The cost: a `drop_while` block of more than one parameter over a boxed Array pays the bind the other stages pay, 9 instructions an element, also where no element turns out to be an Array and master's answer was right (`{ |x, y| x < 199990 }` over 200,000 Integers and Floats mixed, ten times: 230,266,434 to 248,265,646, 7.8% more; the same with the bound read from a local). No static test can tell the two apart: what a boxed Array holds is known only when it runs, and one Array among its elements is what the second parameter is there for.

`emit_lazy_pipeline_expr` (`src/codegen_call.c`) binds a stage's block parameters in three steps: `emit_boxed_step_binds` (a rest, an optional, a post, a keyword), then `emit_iter_autosplat` (`|k, v|` over a pair), then the one name. The `drop_while` branch had a copy of the last step alone, so the first parameter was bound to the whole element and the others were never bound.

The second commit moves the three steps into one function, `lazy_stage_bind`, with no change in generated C (`tools/cident.sh` against the first commit answers `6453 identical, 0 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`). The third has the `drop_while` branch call it where the one name left the block wrong (`lazy_dw_binds_all`): the block has no first parameter; or its body names an optional, a rest, a post or a keyword; or the element can be an Array and the body names a parameter of a block with more to take. Every other block keeps the lines it had and emits the C it did: one plain parameter; more than one over an Integer Range or an Integer, Float or String Array, where the second reads nil; a block that names none of its parameters; a block with a keyword, a `**` or a post that the body never reads, which has no local for the bind to write (`{ |x, k: 1| x < 2 }`); and, over an Enumerator, a block that takes one value whole (`{ |x, k: 1| }`, `{ |x = 7| }`, `{ |*r| }`). An Enumerator's step can be more than one value (`each_with_index`), which every stage reads as one Array, and that block would be handed the pair. A block that holds a `break` is bound as it was too, as the first commit reads it as it was.

Bound whole, the block also runs a `redo`, which the first commit leaves refused in a `drop_while` block of more than one parameter, and its `next` has the parameters to read: `{ |k, x| next if x > 3; x.odd? }` over a Hash raised on the nil `x`.

Of 2,915 generated programs with a lazy `drop_while`, run on master 8dc55225 (1,820 of them 26 parameter lists over 10 sources, with a body that names none, the first or all of the parameters, or holds a `redo`; 839 the first commit's, with a `next`, a `break`, a block-local or a `redo` in the block; 256 an optional or a rest list alone and beside another stage, over `each_with_index`, a Hash, pairs and Integers), each through master, the first commit and this branch, plain and with `--share-strings`: 281 that were wrong, 140 that raised, 451 that did not build and 156 that were refused are right. 98 are right before and after and 1,765 emit the C of the first commit. 24 are wrong, by the fault below: 12 that were wrong and 12 that did not build. None that is right on master is wrong, refused or not building. The other 8,544 of the first commit's 9,383 programs emit its C, plain and with the flag.

One kind goes from a raise or a C error to a wrong answer, by a fault master has in the stage beside it and that is reached now that the parameters bind. Over `each_with_index` a stage is handed the pair where CRuby hands it the first value, the stage before the `drop_while` or after it: `[4, 7, 1].each_with_index.lazy.drop_while { |x, i| x < 5 }.map { |z| [z] }.to_a` raised in `drop_while` and answers `[[[7, 1]], [[1, 2]]]` for `[[7], [1]]`, and after a `map { |e| e }` the block of `{ |x = 7| }`, `{ |x = 7, y = 8| }`, `{ |*r| }` or `{ |*r, z| }` stopped at a C error and is handed the pair. On master `[4, 7, 1].each_with_index.lazy.map { |e| e }.to_a` prints `[[4, 0], [7, 1], [1, 2]]` for `[4, 7, 1]`, and `select { |x, i| x >= 5 || i > 0 }` in the stage's place answers the same. The 24 above are of this kind, each over `each_with_index` with a `map { |e| e }` before the `drop_while` or after it, and each prints for its Array the line master prints with `reject` in the `drop_while`'s place.

Not here, as on master: `{ |x, *| ... }` binds `x` to the whole element, in every stage; over an Enumerator, where the `drop_while` is the first stage, `{ |x = 7| }` and `{ |*r| }` do not build and `{ |x, k: 1| }` reads nil for `k`; and a block of more than one parameter that holds a `break` still binds its first alone.

The test is `test/lazy_drop_while_block_params.rb` (29 lines printed; master does not build it, and line by line differs on 14: 9 raise, 2 are wrong, 2 do not build and 1 is refused). `tools/cident.sh` for the third commit against the second answers `6453 identical, 0 differ, 1 refusal changes, 0 refused by both, 0 not in the reference`: the new test, which the commit below it refuses at its `redo` line. `docs/limitations.md` narrows the `redo` row's `drop_while` case. optcarrot's C does not change.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; not yet run under Ruby 4.0)
- [ ] Values past 2^31 are marked `# spinel: int64` (none in the tests)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [x] Depends on: # (the change "A lazy stage's block answers with its next, has fresh locals and runs a redo": this branch is that one's commit and two more)
