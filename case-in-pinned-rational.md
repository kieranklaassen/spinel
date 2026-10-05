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

Spinel stops in the C compiler: `error: invalid operands to binary ==`. CRuby prints `hit`.

The pinned value was compared with C's `==`, which a struct does not have. `emit_pm_eq` already compares an Array, a Hash and a Bignum subject boxed, by `sp_poly_eq`, with the value rooted. A Rational beside an Integer, a Float, a Bignum or a Rational, on either side, and two Complex now go the same way.

Checked:

- `test/case_in_pinned_rational.rb` does not build on master and passes here, also under `SPINEL_GC_STRESS=1` and `2`.
- 1,116 generated programs, each against CRuby: a Rational, a Complex, an Integer, a Float, a Bignum, a String and a Symbol beside a Rational or a Complex, pinned, under `when` (as a statement, as a value, held in a local, in a list of two) and with `===`. 70 that did not build on master are right here, all of them pinned. No program that is right on master changes, and none that did not build on master answers wrongly here.
- Generated C, `tools/cident.sh` against master: only the new test differs. optcarrot and the benchmarks are byte-identical.

Left alone.

- A Complex beside a real number still does not build, where CRuby matches:

  ```ruby
  x = Complex(2, 0)
  n = 2
  case x
  in ^n then puts "hit"
  else puts "miss"
  end
  ```

  Boxed, the two do not compare equal, so comparing them as the others would turn the build failure into a wrong `miss`.
- A Rational or a Complex beside a String, a Symbol or nil still does not build.
- `when` beside a Rational or a Complex is the next pull request.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
