<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A Rational literal arm missed a Rational or a Float that equals it.

```ruby
case Rational(1, 2)
when 0.5r then puts "hit"
else puts "miss"
end
```

Spinel prints `miss`. CRuby prints `hit`. `case 0.5` with `when 0.5r` and `case Complex(0, 2)` with `when 2i` missed the same way. An arm that is not a literal did not build: `when Rational(1, 2)` beside a Rational stops in the C compiler with `error: invalid operands to binary ==`.

The literal arm read its subject as an Integer, and the other arms compared the two with C's `==`, which a struct does not have. A Rational beside an Integer, a Float, a Bignum or a Rational, on either side, and two Complex are now compared as a pinned value is (`emit_pm_eq`: boxed, by `sp_poly_eq`). The literal arms keep their own test beside an Integer subject, where it was right.

Checked:

- `test/case_when_rational.rb` does not build on master and passes here, also under `SPINEL_GC_STRESS=1` and `2`.
- 1,116 generated programs, each against CRuby: a Rational, a Complex, an Integer, a Float, a Bignum, a String and a Symbol beside a Rational or a Complex, under `when` (as a statement, as a value, held in a local, in a list of two), pinned and with `===`. Against the pull request this stands on: 266 that did not build are right here, and 6 that answered wrongly (the literal arms) are right here. No program that is right there changes, and none that did not build answers wrongly here.
- Generated C, `tools/cident.sh` against master: only the two new tests differ. optcarrot and the benchmarks are byte-identical.

Left alone.

- A Complex beside a real number still does not build, where CRuby matches:

  ```ruby
  case Complex(2, 0)
  when 2 then puts "hit"
  else puts "miss"
  end
  ```

  Boxed, the two do not compare equal, so comparing them as the others would turn the build failure into a wrong `miss`.
- A Rational or a Complex beside a String, a Symbol or nil still does not build.
- `Rational(1, 2) === x` and `Complex(1, 2) === x` written out: unchanged.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (A pinned Rational or Complex is compared by value)
