<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A rest array or a block handed to `new` could be freed while its object was allocated; the object then kept whatever took its place.

```ruby
class Bag
  def initialize(*r) = @r = r
  def r = @r
end

keep = []
100_000.times do |i|
  xs = [i, i + 1]
  keep << Bag.new(*xs)
end
bad = 0
keep.each_with_index { |b, i| bad += 1 unless b.r == [i, i + 1] }
p bad
```

Master (5390d3002) prints `4`. CRuby prints `0`. The count is the same for 100,000 `Bag.new` with no argument (each then given one element), and for 100,000 `Agg.new { |v| v + i }` kept by `def initialize(&blk) = @blk = blk`. Under `SPINEL_GC_STRESS=2` one such `new` is enough: master aborts, and 40 tests of the corpus die there for this reason alone (`test/class_value_new_splat.rb`, `test/forwarding_initialize_splat_new.rb`, `test/initialize_block_param.rb` among them).

A method roots its parameters before it allocates, so a call may hand it a fresh value nothing else holds. Three arguments are written so: the empty array for a rest no argument lands in (`sp_Bag_new(sp_PolyArray_new())`), the copy a splat makes (`sp_Bag_new(sp_PolyArray_dup(_t6))`) and a block (`sp_Agg_new(sp_proc_new_meta(...))`). The constructor is the one function that allocated first: it made the object and then called `initialize`, whose roots of its parameters came after. It now roots the rest parameter and the block parameter ahead of the allocation, as the Struct constructor above it roots its reference arguments. The block's root has the condition `initialize`'s own has; the rest's is that the constructor hands the rest on, to `initialize` or to the clone a proc drives. The `) {` that each allocation arm printed moves ahead of the arms, so the roots come first in all four: the pooled object, the two exception layouts and the Array subclass.

At a typed `X.new` that spreads nothing, every other argument reaches the constructor from a temp its caller roots, and is right on master at `SPINEL_GC_STRESS=2`: a String, an object, an Array or a Hash literal, a lambda, a default (one or two, given or omitted), a keyword, a keyword rest.

Not in this change, each a value its call leaves unheld: a call that spreads into defaults (`Img.new(**opts)` with `def initialize(x = "a" * 2, y = "c" * 2)`) spells each default in place, and one is freed by the next before the constructor is entered; a `new` through a class value (`kl.new("z" * 2)`) keeps its argument in a temp its dispatch does not root.

`make cident` against master: 6213 identical, 145 differ: the new test and 144 programs with such a constructor, each by those roots and no other line (292 roots). Of the 144, 94 were right at `SPINEL_GC_STRESS=2` and stay right, 40 died there and are right, and 10 still die there of faults this does not touch (three of them get further first); none that was right at any level is otherwise. A constructor with neither a rest nor a block parameter is the C it was. 200,000 `new` under callgrind: with no argument for the rest, 40,694,663 instructions before and 43,568,310 after (+7.1%); with a splat, 68,697,004 and 70,697,142 (+2.9%); with a block written at the call, 93,761,795 and 95,380,990 (+1.7%). A rest collected from two arguments and a proc passed by `&`, which their caller holds, pay 14 instructions a call for a root they did not need (+5.2% and +6.4%): the root is in the constructor, which is one function for every `new` of its class, through a class value and `super` too, and cannot tell the call that holds its argument from the one that does not.

Test: `test/new_rest_and_block_held.rb`, in `GC_STRESS_TESTS`, 16 lines; master prints `kept in a list: 2` and `a rest of a yielding initialize: 1` in a plain run and aborts at `SPINEL_GC_STRESS=2`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
