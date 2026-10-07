<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A block handed to `new` and kept by `initialize(&blk)` could be freed while its object was allocated; the object then called whatever took the proc's place.

```ruby
class Agg
  def initialize(&blk) = @blk = blk
  def feed(v) = @blk.call(v)
end

keep = []
100_000.times { |i| keep << Agg.new { |v| v + i } }
bad = 0
keep.each_with_index { |b, i| bad += 1 unless b.feed(1) == i + 1 }
p bad
```

Master (5390d3002) prints `4`. CRuby prints `0`. Under `SPINEL_GC_STRESS=2` one such `new` is enough: master dies with a segmentation fault, and 25 tests of the corpus die there for this reason alone (`test/initialize_block_param.rb`, `test/kept_block_param_not_hash.rb`, `test/new_block_forwarding.rb` among them).

The `new` site builds the proc in place as the constructor's argument (`sp_Agg_new(sp_proc_new_meta(...))`), and `sp_Agg_new` allocated the object before anything held it: `initialize` roots its block parameter, but runs after the allocation. The constructor now roots the block parameter first, on the condition `initialize`'s own root has, as the Struct constructor above it roots its reference arguments. The `) {` that each allocation arm printed moves ahead of the arms, so the root comes first in all four: the pooled object, the two exception layouts and the Array subclass.

`make cident` against master: 6279 identical, 79 differ: the new test and 78 programs with such a constructor, each by that root and no other line (121 roots). Of the 78, 40 were right at `SPINEL_GC_STRESS=2` and stay right, 25 died there and are right, and 13 still die there of other faults; none that was right at any level is otherwise. A constructor with no block parameter is the C it was. 200,000 `new` under callgrind: with a block written at the call, 93,761,678 instructions before and 95,380,594 after (+1.7%); with a proc passed by `&`, which its caller holds, 43,765,756 and 46,569,192 (14 instructions a call for a root it did not need).

Test: `test/initialize_block_param_held.rb`, in `GC_STRESS_TESTS`, 9 lines; master prints `kept in a list: 1` in a plain run and aborts at `SPINEL_GC_STRESS=2`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
