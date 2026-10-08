<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
p [1, 2, 4, 9].slice_when { |a, b| next true if b == a + 1; false }.to_a
# CRuby: [[1], [2, 4, 9]]. master: [[1, 2, 4, 9]]
p [1, 2, 4, 9].chunk_while { |a, b| next false if b == a + 1; true }.to_a
# CRuby: [[1], [2, 4, 9]]. master: [[1, 2, 4, 9]]
```

Over an Integer Array or Range, a `next` in the block kept the run going whatever its value was. Under a `begin` a raise after the walk also went uncaught, and in a method with an `ensure` the walk's answer was lost:

```ruby
def runs(a)
  p a.chunk_while { |x, y| next true if y == x + 1; false }.to_a
ensure
  puts "done"
end
runs([1, 2, 4])   # CRuby: [[1, 2], [4]], then done. master: done
```

The cost: a block with such a `next` that master ran right pays the boxed slot its answer is read through, 7 instructions a pair (`chunk_while { |x, y| next y > x if y == 99; y == x + 7 }` over 200,000 Integers, ten times: 488,981,957 to 502,982,220). Master ran it right where the `next` never fires or answers what keeps the run, and under a `begin` where it keeps the run and nothing raises afterwards. No static test tells these apart: whether the `next` fires, what it answers and whether a raise follows are known only when the program runs.

`emit_chunk_while_expr` and the slice_when arm of `emit_slice_when_chunk_inspect_expr` (`src/codegen_fold.c`) write the block's statements into the walk's own C loop and read the last one as the answer. So a `next` was that loop's `continue`. The element is in the run before the block is asked, and the run went on. Under a `begin` the `continue` also popped the rescue's frame, as a `next` that leaves the `begin` does, and under an `ensure` it left through the ensure.

Both now read the block through `emit_block_cond_next`, as `emit_chunk_family_runs` does for a Float Array or a mixed one, which are right on master. They do so where a `next` of the block's own can answer otherwise (`chunk_next_keeps_run`). Where every such `next` is one the `continue` already answers, the C is what it was: a `next` with a literal that is true in `chunk_while` (`next true if y == x + 1`); `next false`, `next nil` or a bare `next` in `slice_when`; and a `next` that is the block's value (`{ |x, y| next y > x + 1 }`). Under a `begin` or an `ensure` only the last of these is left as it was.

Of 4,600 generated programs, run on master 80e28dd2 (3,400: 17 block bodies in `chunk_while` and in `slice_when`, over an Integer Array, a Range, a filtered Array, a Float Array and a mixed one, read ten ways, at the top level and in a method; 1,200: 20 bodies over the three Integer sources with the walk under a `begin`, an `ensure` or a loop, ten ways), each through master, the change below this one and this branch: 1,097 that were wrong are right, 398 that raised are right and 2 that crashed are right. 123 are right before and after with the block read the new way, at the cost above, and 2,980 emit the C of the change below. None that is right on master is wrong, refused or not building, and with `--share-strings` every count is the same. Over the first 3,400 and the 1,152 programs of the change below, this branch's C differs from that change's exactly where this change alone differs from master.

Not here, as on master: `chunk { }.to_a.inspect` over an Integer Array still reads a `next` in its block as the walk's `continue` (`chunk { |x| next 7 if x == 2; x > 3 }` drops the 2).

The test is `test/chunk_while_next_value.rb` (27 lines printed; master is wrong on the first 20 and stops before the last, at the raise a `next` left uncaught). `tools/cident.sh` against the change below this one answers `6478 identical, 1 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`, the one being the test. optcarrot's C does not change.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; not yet run under Ruby 4.0)
- [ ] Values past 2^31 are marked `# spinel: int64` (none in the test)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [x] Depends on: # (the change "slice_when read through inspect tests its block's value by Ruby's truth": this branch is that one's commit and one more)
