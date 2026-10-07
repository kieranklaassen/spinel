<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
p [[1, 2], [3, 9], [5, 1]].lazy.drop_while { |x, y| y < 4 }.to_a
# CRuby: [[3, 9], [5, 1]]. master: undefined method '<' for nil (NoMethodError)
p [1, [3, 4], 5].lazy.drop_while { |x, y = 9| y == 9 }.to_a
# CRuby: [[3, 4], 5]. master: [1, [3, 4], 5]
```

`{ |*r| ... }` and `{ |*r, z| ... }` did not build.

The cost: a `drop_while` block of more than one parameter over a boxed Array pays the bind the other stages pay, 9 instructions an element, also where no element turns out to be an Array and master's answer was right (`{ |x, y| x < 199990 }` over 200,000 Integers and Floats mixed, ten times: 230,266,420 to 248,265,632, 7.8% more). No static test can tell the two apart: what a boxed Array holds is known only when it runs, and one Array among its elements is what the second parameter is there for.

`emit_lazy_pipeline_expr` (`src/codegen_call.c`) binds a stage's block parameters in three steps: `emit_boxed_step_binds` (a rest, an optional, a post, a keyword), then `emit_iter_autosplat` (`|k, v|` over a pair), then the one name. The `drop_while` branch had a copy of the last step alone, so the first parameter was bound to the whole element and the others were never bound.

The second commit moves the three steps into one function, `lazy_stage_bind`, with no change in generated C (`tools/cident.sh` against the first commit answers `6416 identical, 0 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`). The third has the `drop_while` branch call it where the one name left the block wrong (`lazy_dw_binds_all`): the block has no first parameter; or its body names an optional, a rest, a post or a keyword; or the element can be an Array and the body names a parameter of a block with more to take. Every other block keeps the lines it had and emits the C it did: one plain parameter; more than one over an Integer Range or an Integer, Float or String Array, where the second reads nil; a block that names none of its parameters; a block with a keyword, a `**` or a post that the body never reads, which has no local for the bind to write (`{ |x, k: 1| x < 2 }`); and, over an Enumerator, a block that takes one value whole (`{ |x, k: 1| }`, `{ |x = 7| }`, `{ |*r| }`). An Enumerator's step can be more than one value (`each_with_index`), which every stage reads as one Array, and that block would be handed the pair. A block that holds a `break` is bound as it was too, as the first commit reads it as it was.

Bound whole, the block also runs a `redo`, which the first commit leaves refused in a `drop_while` block of more than one parameter, and its `next` has the parameters to read: `{ |k, x| next if x > 3; x.odd? }` over a Hash raised on the nil `x`.

Of 2,659 generated programs with a lazy `drop_while` (1,820 of them 26 parameter lists over 10 sources, with a body that names none, the first or all of the parameters, or holds a `redo`; 839 the first commit's, with a `next`, a `break`, a block-local or a `redo` in the block), each through master, the first commit and this branch, plain and with `--share-strings`: 217 that were wrong, 152 that raised, 347 that did not build and 156 that were refused are right. 96 are right before and after and 1,691 emit the C of the first commit. None that is right on master is wrong, refused or not building, and none that raised, was refused or did not build is wrong. The 6,976 programs of the first commit's sets that hold no `drop_while` emit its C.

One kind, in none of these programs, goes from a raise to a wrong answer, by a fault master has in the stage beside it and that is reached now that the parameters bind. Over `each_with_index` the block after the stage is handed the pair where CRuby hands it the first value: `[4, 7, 1].each_with_index.lazy.drop_while { |x, i| x < 5 }.map { |z| [z] }.to_a` raised in `drop_while` and answers `[[[7, 1]], [[1, 2]]]` for `[[7], [1]]`, and so in `filter_map`, `flat_map` and the block of `take_while`. On master `select { |x, i| x >= 5 || i > 0 }` in the stage's place answers the same.

Not here, as on master: `{ |x, *| ... }` binds `x` to the whole element, in every stage; over an Enumerator `{ |x = 7| }` and `{ |*r| }` do not build and `{ |x, k: 1| }` reads nil for `k`; and a block of more than one parameter that holds a `break` still binds its first alone.

The test is `test/lazy_drop_while_block_params.rb` (29 lines printed; master does not build it, and line by line differs on 14: 9 raise, 2 are wrong, 2 do not build and 1 is refused). `tools/cident.sh` for the third commit against the second answers `6416 identical, 0 differ, 1 refusal changes, 0 refused by both, 0 not in the reference`: the new test, which the commit below it refuses at its `redo` line. `docs/limitations.md` narrows the `redo` row's `drop_while` case. optcarrot's C does not change.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; not yet run under Ruby 4.0)
- [ ] Values past 2^31 are marked `# spinel: int64` (none in the tests)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [x] Depends on: # (the change "A lazy stage's block answers with its next, has fresh locals and runs a redo": this branch is that one's commit and two more)
