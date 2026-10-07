<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

The cost, in instructions for one op-assign on a boxed attribute against master e527d205d274 (callgrind, an Integer in the slot, 2,000,000 turns of a `while` loop, gcc / clang; `&=`, `|=` and `^=` alike but where said): `b.v &= 3` and `b.v &= (i + 3)`, one fewer / one fewer; `b.v &= a[i & 3]`, one more / two more; `b.v &= a[1]`, two more / two more (`^=`: one / two); `b.v &= b.mask(i)`, one more for `&=` and `^=` and two for `|=`, with both compilers; `b.v &= b.three`, one more for `&=` and one fewer for the other two / level; `b.v ^= (5 <=> b.w)` with nil in `w`, level / seven fewer. Where a class of the program defines the operator's name the temp is taken as well: `(i + 3)` beside a class with a `+` of its own, level / one more; beside a class with a `[]` of its own, `a[i & 3]` two more / four more and `a[1]` three more (`^=`: four) / four more.

`&=`, `|=` and `^=` on an attribute whose slot is boxed read the slot as an Integer whatever it held:

```ruby
class Box
  attr_accessor :v
  def initialize(v) = @v = v
end
b = Box.new(["s", 1][0])
b.v &= 1
p b.v                 # 0; Ruby raises NoMethodError
```

A Float answered from its integer part, true from 1 and an Array from 0, and a right operand of true or an Array was read the same way. The three forms now go through `sp_poly_bitop`, as `+=` to `>>=` on the same slot go through their `sp_poly_` helpers and as a boxed local's `x &= 1` does. Two Integers answer in line first (`sp_poly_bitop_int_first`, new beside `sp_poly_bitop`).

The slot is still read before the right operand runs (but for the boxed-receiver case below): where the operand can run the program's code, the slot's value is bound to a rooted temp first. That is a call that may write the slot (`o.v ^= o.bump`), and also what passes for a plain read by its static types: a comparison with a boxed argument reaches the argument's `coerce` (`o.v ^= (5 <=> o.w)`), and `1.5 + 2` or `a[i]` is the program's own method once it reopens Float or Array. So the slot is read in place only where the operand is a plain read and no call in it has a name a class of the program defines, or an argument that is no Integer or Float.

A boxed attribute holding nil raised NoMethodError; it now answers false or true, as Ruby does and as a boxed local holding nil already did. An Integer attribute, with or without nil, keeps its own slot and its own code.

Not covered, as on master: `+=` to `>>=` on a boxed attribute read the slot after an operand that writes it (`o.v += o.bump`), and so do the three forms through a boxed receiver when the operand's own statements are set down ahead of the dispatch: a block, an Array literal holding a call, a `begin ... end`, a sequence in a rescue body (`r.v ^= [o.bump, 1].first`).

One kind of line raised before and is now wrong in silence, by a fault master has without this change: where a program reopens TrueClass, FalseClass or NilClass, its own `&`, `|`, `^`, `!`, `==` and `!=` are not called (`x = (t & true)` runs the builtin one). With nil in the slot, `o.v |= (t & true)` and `^=` with any of those as the operand, and `&=` under NilClass's own `&`, raised NoMethodError; they now answer from the builtin's value, which is what master prints for `o.v = o.v | (t & true)`.

Both tests fail on master. The generated C of one corpus program changes (`test/poly_nil_op_assign.rb`, one line); optcarrot's is unchanged.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
