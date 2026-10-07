<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

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

A Float answered from its integer part, true from 1 and an Array from 0, and a right operand of true or an Array was read the same way. The three forms now go through `sp_poly_bitop`, as `+=` to `>>=` on the same slot go through their `sp_poly_` helpers and as a boxed local's `x &= 1` does.

A boxed attribute holding nil raised NoMethodError; it now answers false or true, as Ruby does and as a boxed local holding nil already did. An Integer attribute, with or without nil, keeps its own slot and its own code.

The test fails on master. The generated C of one corpus program changes (`test/poly_nil_op_assign.rb`, one line); optcarrot's is unchanged. An Integer in a boxed slot now pays the helper's call, 8 to 11 instructions an op-assign (callgrind, gcc and clang), as a boxed local does.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
