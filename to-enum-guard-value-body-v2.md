## What this changes

```ruby
class Pair
  def each
    return to_enum(:each) unless block_given?
    yield 1
    yield 2
    [1, 2]
  end
end
pair = Pair.new
p pair.each { |x| p x }
p pair.each.to_a
```

did not build: `assignment to 'sp_Enumerator *' from incompatible pointer type 'sp_IntArray *'`. CRuby prints `1`, `2`, `[1, 2]`, `[1, 2]`.

A method that returns `to_enum(:m) unless block_given?` has its return pinned to Enumerator unless its block form answers a value. Among the literals `te_tail_is_value` took a Hash, a String, a Symbol and a number for a value, and no other, so the Array was stored through the pinned return. It now takes an Array, a Range, an interpolated String, a Regexp, a Rational, a Complex and a lambda too, where one is the last expression of the code that runs with a block: what follows the guard's return, or the block arm of `if block_given?`, and the same for a test of a `&b` parameter. The same method ending `v = [1, 2]` already built and printed this.

Not in this change: such a literal returned early beside a `self` tail, ending the arm that runs without a block, or after another `return` or a second test of `block_given?`. Those methods get the same C as before, so one that builds today, pinned, still does (`to_enum_literal_pinned`), and one that did not build still does not. A method that builds now meets the faults `.with_index` on its blockless call already has when it ends `v = [1, 2]` (nil for a receiver read out of an Array of two classes, NoMethodError when the block is taken as `&b`).

`make cident REF=dafa0d04`: 6,281 identical, 0 differ; `to_enum_literal_tail` is no longer refused.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (`to_enum_literal_tail` is equal under CRuby 4.0.7; `to_enum_literal_pinned`, written from CRuby 3.3.6, is owed)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: # (nothing)
