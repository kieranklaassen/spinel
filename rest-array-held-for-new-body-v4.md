<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A rest array handed to `new` could be freed while its object was allocated; the object then kept whatever took its place. The cure is one root in the constructor, and a constructor that was right pays it too: 200,000 `new` under callgrind, `Bag.new` is 36,489,944 instructions before and 39,363,359 after (+7.9%), `Bag.new(*xs)` 64,097,360 and 66,497,362 (+3.7%), `Bag.new(i, 2)` 49,372,008 and 52,184,135 (+5.7%). A class with no rest parameter pays nothing.

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

Master (a2bd89005) prints `4`, built with gcc and with clang. CRuby prints `0`. The count is the same for 100,000 `Bag.new` with no argument, each then given one element. Under `SPINEL_GC_STRESS=2` one such `new` is enough: master aborts, and 14 tests of the corpus fail there for this reason alone (`test/class_value_new_splat.rb`, `test/forwarding_initialize_splat_new.rb`, `test/post_rest_keyword_hash.rb` among them). A rest between other parameters (`def initialize(a, *r, b, c)`) and the rest of an exception's `initialize` filled by `raise E2, i` are lost the same way, one `new` in 1,000,000 in a plain run.

A method roots its parameters before it allocates, so a call may hand it a fresh value nothing else holds. A rest is written so when no argument lands in it (`sp_Bag_new(sp_PolyArray_new())`) and when a splat fills it (`sp_Bag_new(sp_PolyArray_dup(_t6))`). The constructor is the one function that allocated first: it made the object and then called `initialize`, whose root of the rest came after. It now roots the rest parameter ahead of the allocation, as the Struct constructor above it roots its reference arguments, when it hands the rest on, to `initialize` or to the clone a proc drives; a constructor whose `initialize` is inlined at the call is called with no rest and stays as it was. The `) {` that each allocation arm printed moves ahead of the arms, so the root comes first in all four: the pooled object, the two exception layouts and the Array subclass.

Depends on the pull request "An Array a call returns is held while its elements are boxed": `sp_typed_to_poly` does not hold its source, so `take(*floats(1))` prints `[]` under `SPINEL_GC_STRESS=2` on master, and with this root alone `Box.new(*floats(1))` goes from an abort there to that `[]`. A splat of the Integers, Strings, Symbols or mixed values a method returns is right.

Not in this change, each a value its call leaves unheld: a block handed to `new` (`Agg.new { |v| v + i }`), which the call must hold; a call that spreads into defaults (`Img.new(**opts)` with `def initialize(x = "a" * 2, y = "c" * 2)`), which spells each default in place; a `new` through a class value (`kl.new("z" * 2)`), whose dispatch keeps the argument in a temp it does not root; a rest array and a block both built at the call.

`make cident` against master: 6279 identical, 98 differ: the new test and 97 programs with such a constructor, each by that root and no other line (177 roots). Of the 97, 70 were right at `SPINEL_GC_STRESS=2` and stay right, 14 failed there and are right, and 13 still die there of faults this does not touch; none that was right at any level is otherwise. Where a class method forwards its rest and its block (`def self.make(*a, &b) = new(*a, &b)`), master loses the block in a plain run; such a program aborted at `SPINEL_GC_STRESS=2` and now prints there the wrong line its plain run prints on master. A constructor with no rest parameter is the C it was. The program measured above is `class Bag; def initialize(*r) = @r = r; end` and the loop. `Bag.new(i, 2)` collects its rest from two arguments its caller holds and pays for a root it did not need: the root is in the constructor, which is one function for every `new` of its class, through a class value and `super` too, and cannot tell the call that holds its rest from the one that does not.

Test: `test/new_rest_held.rb`, in `GC_STRESS_TESTS`, 8 lines; master prints `no argument for the rest: 4` and `a splat for the rest: 1` in a plain run and aborts at `SPINEL_GC_STRESS=2`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [x] Depends on: # (An Array a call returns is held while its elements are boxed)
