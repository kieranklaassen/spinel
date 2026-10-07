<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

`in ^y` beside a Rational or a Complex did not build.

```ruby
x = Rational(1, 2)
y = Rational(1, 2)
case x
in ^y then puts "hit"
else puts "miss"
end
```

Master (dafa0d047) stops in the C compiler: `error: invalid operands to binary == (have 'sp_Rational' and 'sp_Rational')`. CRuby prints `hit`.

The pinned value was compared with C's `==`, which a struct does not have. `emit_pm_eq` already compares an Array, a Hash and a Bignum subject boxed, by `sp_poly_eq`, with the value rooted. A Rational beside an Integer, a Float, a Bignum or a Rational, on either side, and two Complex now go the same way.

Not in this change: a Complex beside a real number (`Complex(2, 0)` against a pinned `2`) still does not build. Boxed, the two do not compare equal, so comparing them as the others would turn the build failure into a wrong `miss`.

Test: `test/case_in_pinned_rational.rb`, 16 lines; it does not build on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
