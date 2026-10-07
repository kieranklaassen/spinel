<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`uniq` with a block compared the block's values with `==`. Ruby compares them with `eql?`, as `uniq` without a block does. The cost: where the kind of the block's value is known only at run time, each comparison of two keys takes a few tests more before it is answered. `ms.uniq { |x| x }` over 12 boxed values is 3,352 instructions a call before and 3,526 after (+5.2%); with keys of two kinds it is +2.5%, and the Enumerator's `uniq` +0.8%. A block whose value is typed pays nothing.

```ruby
class Tag
  attr_reader :n
  def initialize(n) = @n = n
  def ==(other) = other.is_a?(Tag) && n == other.n
end

p [1, 2, 3].uniq { |x| x.odd? ? 1 : 1.0 }
p [1, 2, 3].uniq { |x| Tag.new(1) }
```

Master (3cb8982d8) prints `[1]` and `[1]`, built with gcc and with clang. CRuby prints `[1, 2]` and `[1, 2, 3]`.

The two loops codegen writes for `uniq { }` keep the block values seen so far and compared each new one with `sp_poly_eq`, so 1 and 1.0 were one key, and so were two objects of a class that defines `==` and no `eql?`. They now compare by `eql?`, as `uniq` without a block does, and so does the Enumerator's `uniq` in the runtime (`each_slice(2).uniq { }`), one word in `lib/spinel_rt.h`. They call `sp_poly_eql_key`, a new inline function: two Integers are answered in place, as `sp_poly_eq` answers them; a pair with no object and no Float in it, or two values of one kind, goes to `sp_poly_eq_slow`, since `eql?` is `==` there; only the rest goes to `sp_poly_eql`, every arm of which but its last line needs an object or the Integer and Float pair. A block whose value is typed as an Integer, a Float, a String, a Symbol, true or false, or nil keeps `sp_poly_eq`, and the C is the C it was.

Not in this change, each wrong on master and the same here, and each `sp_poly_eql`'s own answer: one NaN returned for two elements is one key in CRuby and two here; `1` and `Rational(1, 1)` are one key here; `S.new(1)` and `S.new(1.0)` of a Struct are one key here; a number and an object whose `==` accepts the number are one key when the object came first. `each_with_index.uniq { }` is refused and `(1..4).lazy.uniq { }` raises, as before.

`make cident` against master: 6387 identical, 6 differ: the new test and 5 tests of the corpus (`test/uniq_block.rb`, `test/uniq_block_boxed_receiver.rb`, `test/uniq_block_pair_splat.rb`, `test/boxed_walk_step_binds.rb`, `test/builtin_iter_step_frame.rb`), by the comparison call of 19 loops and no other line. Each of the 5 prints its `.expected`, plain and under `SPINEL_GC_STRESS=2`.

602 programs, 14 receivers (among them an Array literal, a variable, a method's result, `uniq!`, a Hash, a Range, `map { }.uniq { }`, `.lazy`, `each_slice`, a boxed Array) by 43 kinds of key, each against CRuby: 393 right before and after, 72 wrong before and right now, 48 wrong before and after (the four kinds above), 89 refused or raising before and after. None that was right is otherwise, with `--share-strings` too. Under callgrind, built by gcc 13.3 at `-O2`, 20,000 calls: `xs.uniq { |x| x % 5 }` 25,428,213 instructions before and after; `words.uniq { |s| s }` over Strings 158,539,958 before and after; `ms.uniq { |x| x }` over 12 boxed values 67,043,172 and 70,523,171 (+5.2%); keys of two kinds, `xs.uniq { |x| x.odd? ? x : x.to_s }`, 106,174,416 and 108,814,382 (+2.5%); the Enumerator's, `ms.each_slice(2).uniq { |pair| pair[0] }`, 66,162,067 and 66,702,067 (+0.8%). `sp_poly_eql` called from the loops with no test before it costs +36.5%, +22.8% and +3.9%, which is why the helper is there.

Test: `test/uniq_block_keys_eql.rb`, 13 lines; master is wrong in 8.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
