<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
p [[1, 2], [3, 9], [5, 1]].lazy.drop_while { |x, y| y < 4 }.to_a
# CRuby: [[3, 9], [5, 1]]. master: undefined method '<' for nil (NoMethodError)
p [1, [3, 4], 5].lazy.drop_while { |x, y = 9| y == 9 }.to_a
# CRuby: [[3, 4], 5]. master: [1, [3, 4], 5]
```

`{ |*r| ... }` and `{ |*r, z| ... }` did not build.

`emit_lazy_pipeline_expr` (`src/codegen_call.c`) binds a stage's block parameters in three steps: `emit_boxed_step_binds` (a rest, an optional, a post), then `emit_iter_autosplat` (`|k, v|` over a pair), then the one name. The `drop_while` branch had a copy of the last step alone, so the first parameter was bound to the whole element and the others were never bound.

The first commit moves the three steps into one function, `lazy_stage_bind`, with no change in generated C (`tools/cident.sh` against master a2bd8900 answers `6375 identical, 0 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`). The second has the `drop_while` branch call it. A block of one plain parameter emits the C it did.

Of 4,515 generated programs, 504 of them parameter forms (12 parameter lists, 7 sources, 6 stages), 167 become right: 126 that raised, 21 that were silently wrong and 20 that did not build. 4,312 emit master's C, and none that is right on master changes its answer. The 1,815 of them also run with `--share-strings` answer the same there.

Fifteen go from a raise or a build failure to a wrong answer. Each is a fault master has in the stage beside it, reached now that the parameters bind:

- a bare `next` in the block (14): `{ a: 1, b: 5, c: 2 }.lazy.drop_while { |k, x| next if x > 3; x.odd? }.to_a` raised and answers `[[:c, 2]]` for `[[:b, 5], [:c, 2]]`. The `next` is the pipeline's own `continue`: with one parameter, `[1, 5, 2].lazy.drop_while { |x| next if x > 3; x.odd? }.to_a` answers `[2]` for `[5, 2]` on master.
- an optional first parameter over `each_with_index` (1): `[4, 7].each_with_index.lazy.drop_while { |x = 7| x.inspect.size.even? }.to_a` did not build and answers `[]` for `[[4, 0], [7, 1]]`: the parameter is handed the pair. So it is on master in `take_while { |x = 7| x.inspect.size.odd? }` (`[]`) and in `map { |x = 7| x }` (the pairs, for `[4, 7]`).

The same pair, in none of these programs: over `each_with_index`, a `map { |z| ... }` after the stage is handed the pair where CRuby hands it the first value. `[4, 7, 1].each_with_index.lazy.drop_while { |x, i| x < 5 }.map { |z| [z] }.to_a` raised in `drop_while` and answers `[[[7, 1]], [[1, 2]]]` for `[[7], [1]]`, as `drop_while { |x, i| false }` and `select { |x, i| true }` in its place do on master.

The test is `test/lazy_drop_while_block_params.rb` (14 lines printed; master does not build it, and line by line differs on 11: 7 raise, 2 are wrong and 2 do not build). `tools/cident.sh` for the second commit answers `6375 identical, 1 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`, the one being the new test. optcarrot's C does not change.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; not yet run under Ruby 4.0)
- [ ] Values past 2^31 are marked `# spinel: int64` (none in the tests)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
