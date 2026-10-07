<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A Rational literal arm missed a Rational or a Float that equals it, and an arm that is not a literal did not build.

```ruby
case Rational(1, 2)
when 0.5r then puts "hit"
else puts "miss"
end
```

Master (dafa0d047) prints `miss`. CRuby prints `hit`. With `when Rational(1, 2)` in its place master stops in the C compiler: `error: invalid operands to binary == (have 'sp_Rational' and 'sp_Rational')`.

The literal arm read its subject as an Integer, and the other arms compared the two with C's `==`, which a struct does not have. A Rational beside an Integer, a Float, a Bignum or a Rational, on either side, and two Complex are now compared as a pinned value is (`emit_pm_eq`: boxed, by `sp_poly_eq`). The literal arms keep their own test beside an Integer subject, where it was right.

Not in this change: a Complex beside a real number (`case Complex(2, 0)` with `when 2`) still does not build. Boxed, the two do not compare equal, so comparing them as the others would turn the build failure into a wrong `miss`.

Test: `test/case_when_rational.rb`, 25 lines; it does not build on master.

This sits on the pull request for a pinned Rational or Complex: it compares through the branch that one adds to `emit_pm_eq`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
