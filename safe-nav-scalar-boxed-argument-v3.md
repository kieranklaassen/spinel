<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def id(x) = x
id(:s)
def flt(v) = v ? 1.5 : nil
f = flt(true)
p f&.clamp(1.0, id(1.2))
```

- Before "v&.fdiv(2) and the other Ruby-defined Integer methods keep the &.": `1.2`.
- Master: `undefined method 'clamp' for an instance of Float (NoMethodError)`.
- CRuby and here: `1.2`.

`i&.between?(id(1), id(20))`, on an Integer or a Float, does not build on master (gcc: `invalid operands to binary >=`). That change left every `&.` call to a scalar method written in Ruby on the typed emitter, so that a nil receiver answers nil; only a `.` call goes to its `builtins/comparable.rb` definition. The typed emitter has no arm for `between?`, or for a Float's `clamp`, with a boxed bound.

It has one for a Rational bound: both sides are boxed and compared at run time (`sp_poly_cmp_ck` for `between?`, `sp_num_clamp` for `clamp`), as an Integer's `clamp` does for a boxed bound already. That arm takes a boxed bound too now. Six lines in the code generator, asked of the types as they stand when the call is emitted; the analysis is not touched, and no other call changes its C.

It stands aside in a program that defines a `between?` (for `clamp`, a `clamp`) of its own, in any class or module: the receiver may answer to that one (`class Numeric; def clamp(a, b)`), and there the call keeps master's C.

Not here, on master and here:

- That standing aside is wide: beside an unrelated `Foo#clamp`, `f&.clamp(1.0, id(1.2))` still raises NoMethodError.
- A nil receiver still runs the arguments of `clamp`: `g&.clamp(lg(1.0), lg(5.0))` logs both, with typed bounds as with boxed ones.
- A boxed Range: `f&.clamp(id(1.0..1.2))` raises NoMethodError.
- A Complex bound with no imaginary part: `i&.between?(id(Complex(5, 0)), id(30))` did not build and raises ArgumentError here, where CRuby answers `true`; `i.between?(Complex(5, 0), 30)` raises it on master.
- An Integer receiver that holds -(2**63): `r = -(2**62) * 2; p r&.between?(id(-(2**70)), id(0))` did not build and prints `nil` here, where CRuby prints `true`; `p r&.succ` prints `nil` on master. That Integer is the nil of an Integer slot.
- A Bignum receiver: `b = 2**70; p b&.between?(id(1), id(2**71))` prints `false`; with `.` it prints `true`.
- A boxed receiver: `bx&.between?(id(1), id(20))`, on a value that is an Integer, a Bignum or a String by turns, does not build.
- A bound that answers `coerce`: `i&.between?(M.new(1), 9)` does not build.

Tests: `test/safe_nav_scalar_boxed_argument.rb`, 64 lines, 43 of output; it does not build on master. `test/safe_nav_scalar_own_clamp.rb`, a program with a `Numeric#clamp`: it passes on master and its C is master's.

Generated C against master (`make cident REF=42557a3c0e7c`): 6471 identical, 1 differ, 0 refusal changes. The one is the first test. optcarrot's generated C is byte-identical.

1,736 small programs written for this change, measured on 8dc5522541bb: `between?` and `clamp`, with `&.` and with `.`, on an Integer and a Float that may be nil (nil and not), on a typed Integer, Float and Bignum and on a boxed value, with thirteen pairs of bounds (boxed, typed, nil, a String, a Bignum, a Rational, the two reversed), printed, assigned, in a block and in an interpolation. 1,304 have master's C. The 432 that differ are the `&.` calls to `between?` on a typed Integer or Float and to a Float's `clamp`, with a boxed bound. With gcc and with clang, plain and under `SPINEL_GC_STRESS=1` and `2`: 48 are right in all six on master, all 432 here. Of the 384 more, 288 (`between?`) did not build and 96 (a Float's `clamp`) raised NoMethodError. The 48 are `clamp` on a nil Float, which answers `nil` on both. No program loses a cell.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
