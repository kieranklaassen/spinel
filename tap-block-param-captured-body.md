<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class Bag
  def initialize(a) = @a = a
  def each = @a.each { |v| yield v }
end
bag = Bag.new([1, 2])
p [].tap { |acc| bag.each { |v| acc << v } }   # []; CRuby prints [1, 2]
s = "q".dup
s.tap { |b| bag.each { |v| b << v.to_s } }
p s                                            # "q"; CRuby prints "q12"
```

`{}.tap { |m| bag.each { |v| m[v] = v * 10 } }` raised a TypeError.

A block whose parameter is captured by a proc made inside it (a lambda, or a block handed to a method the program defines with `yield`) has its body wrapped in an immediately-called lambda, so that each iteration captures a fresh cell. `tap` and `then` run their block once, and the wrapper's parameter was a copy of the receiver: a String changed through it kept its old value, an empty Array literal's parameter settled as an Integer, an empty Hash literal's had no type.

The block of a `tap`, `then` or `yield_self` is now left unwrapped when the receiver is a local variable, a Hash literal or an Array literal (an empty Array literal only where the tap's value is read and the block holds no proc literal of the program's own, which is where the inline emitters type its cell).

Left as before: a program class that defines `tap` or `then`, and every other receiver. A String out of a call or an instance variable is still a copy there (`"a".dup.tap { |b| bag.each { b << "x" } }` answers `"a"`).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
