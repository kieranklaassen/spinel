<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`uniq` with a block compared the block's values with `==`. Ruby compares them with `eql?`, as `uniq` without a block does.

Cost, in instructions a call under callgrind, before and after, where the kind of the block's value is known only at run time (a block whose value is typed pays nothing):

| the call | gcc 13.3 | clang 18.1 |
|---|---|---|
| `ms.uniq { \|x\| x }`, 11 Integers and a String | 3,352 to 3,526 (+5.2%) | 2,754 to 2,873 (+4.3%) |
| the same over 12 values of six kinds | 5,469 to 6,001 (+9.7%) | 4,428 to 5,019 (+13.3%) |
| `xs.uniq { \|x\| x.odd? ? x : x.to_s }` | 5,309 to 5,441 (+2.5%) | 4,699 to 4,769 (+1.5%) |
| `ms.each_slice(2).uniq { \|pair\| pair[0] }` | 3,308 to 3,335 (+0.8%) | 3,305 to 3,301 |
| `xs.uniq { \|x\| KS[x % 3] }`, objects of a class with `==`, `eql?` and `hash` | 4,279 to 3,415 | 2,092 to 3,383 (+62%) |
| `xs.uniq { \|x\| Key.new(x % 3) }`, the same class | 4,662 to 4,453 | 2,502 to 4,611 (+84%) |
| `xs.uniq { \|x\| OBJS[x % 3] }`, objects of a class with neither | 4,547 to 2,550 | 3,614 to 2,433 |
| `xs.uniq { \|x\| [x % 3] }` | 11,995 to 9,939 | 11,775 to 11,526 |

Each comparison of two boxed keys takes a few tests more before it is answered. An object of a class with its own `eql?` is now asked that `eql?`, through `sp_poly_eql` as `uniq` without a block asks it; built with clang that call is dearer than the `==` it replaces, built with gcc it is cheaper.

```ruby
class Tag
  attr_reader :n
  def initialize(n) = @n = n
  def ==(other) = other.is_a?(Tag) && n == other.n
end

p [1, 2, 3].uniq { |x| x.odd? ? 1 : 1.0 }
p [1, 2, 3].uniq { |x| Tag.new(1) }
```

Master (9274c732e) prints `[1]` and `[1]`, built with gcc and with clang. CRuby prints `[1, 2]` and `[1, 2, 3]`.

The two loops codegen writes for `uniq { }` keep the block values seen so far and compared each new one with `sp_poly_eq`, so 1 and 1.0 were one key, and so were two objects of a class that defines `==` and no `eql?`. They now compare by `eql?`, as `uniq` without a block does, and so does the Enumerator's `uniq` in the runtime (`each_slice(2).uniq { }`), one word in `lib/spinel_rt.h`. They call `sp_poly_eql_key`, a new inline function: two Integers are answered in place, as `sp_poly_eq` answers them; a pair with no object and no Float in it, or two values of one kind, goes to `sp_poly_eq_slow`, since `eql?` is `==` there; only the rest goes to `sp_poly_eql`, every arm of which but its last line needs an object or the Integer and Float pair. A block whose value is typed as an Integer, a Float, a String, a Symbol, true or false, or nil keeps `sp_poly_eq`, and the C is the C it was.

Not in this change, each wrong on master and the same here, and each `sp_poly_eql`'s own answer: one NaN returned for two elements is one key in CRuby and two here; `1` and `Rational(1, 1)` are one key here; `S.new(1)` and `S.new(1.0)` of a Struct are one key here; a number and an object whose `==` accepts the number are one key when the object came first; `D.new(1)` and `D.new(1.0)` of a Data are one key here; so are `1.0` and `Rational(1, 1)`, and two exceptions equal by `==` (`RuntimeError.new("a")` twice). `each_with_index.uniq { }` is refused and `(1..4).lazy.uniq { }` raises, as before.

`make cident` against master: 6414 identical, 6 differ: the new test and 5 tests of the corpus (`test/uniq_block.rb`, `test/uniq_block_boxed_receiver.rb`, `test/uniq_block_pair_splat.rb`, `test/boxed_walk_step_binds.rb`, `test/builtin_iter_step_frame.rb`), by the comparison call of 19 loops and no other line. Each of the 5 prints its `.expected`, plain and under `SPINEL_GC_STRESS=2`.

602 programs, 14 receivers (among them an Array literal, a variable, a method's result, `uniq!`, a Hash, a Range, `map { }.uniq { }`, `.lazy`, `each_slice`, a boxed Array) by 43 kinds of key, each against CRuby: 393 right before and after, 72 wrong before and right now, 48 wrong before and after (the four kinds above), 89 refused or raising before and after. None that was right is otherwise, with `--share-strings` too. A typed key costs the same before and after: `xs.uniq { |x| x % 5 }` 1,271 instructions a call with gcc and 1,197 with clang, `words.uniq { |s| s }` over Strings 7,927 and 7,256. `sp_poly_eql` called from the loops with no test before it costs +36.5%, +22.8% and +3.9% on the first, third and fourth rows above with gcc, which is why the helper is there.

Test: `test/uniq_block_keys_eql.rb`, 13 lines; master is wrong in 8.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
