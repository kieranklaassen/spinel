<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**A fix with a stated cost.** With gcc a boxed Complex raised to a power pays 2 instructions (0.5% of the loop measured below); an Integer, a Float, a Bignum and a word-sized Rational base are on master's count or one below it. With clang an Integer, a Float and a Bignum base pay 1 and a Complex base 8 (2.8%). Four spellings of the arm were measured (under **Cost**) and this one is the cheapest. A Complex base passes the same two tests as before; the compilers lay the function out 2 and 8 instructions dearer for it, and no spelling brought both to zero.

A Rational whose numerator or denominator is a Bignum, raised to an Integer, answered a Float. A plain run:

```ruby
x = [Rational(2**70, 3), :a][0]
p x ** 2, x ** -1, x ** 0
```

```
spinel diff: output-diff
  program: power.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,3 +1,3 @@
-(1393796574908163946345982392040522594123776/9)
-(3/1180591620717411303424)
-(1/1)
+1.548662861009071e+41
+2.541098841762901e-21
+1.0
```

`sp_poly_pow` (lib/spinel_rt.h) keeps an exact receiver exact, but its Rational arm asked for the word-sized Rational alone, so a Rational of Bignums fell to `pow(double, double)`: a Float, and past 2**53 a rounded one.

`sp_brat_pow` (lib/sp_format.c) raises each part in Bignums, swaps them for a negative exponent, and raises ZeroDivisionError for zero to a negative one, as `sp_rational_pow` does in words. A Rational exponent that is an Integer (`2r`) is taken the same way. A Float exponent and a Rational one that is no Integer answer a Float as before.

**Measured against CRuby 3.3.6 on master 3d629868.** 56 generated programs: fourteen boxed bases (nine Rationals of Bignums: a Bignum numerator, a Bignum denominator, each of them negative, one whose parts fit a word again, an Integer, zero, one and minus one held as such; a word-sized Rational, an Integer, a Float, a Bignum, a Complex) to twenty-one exponents (0, 1, 2, 3, 5, -1, -2, -3, `2r`, `-1r`, `0r`, `Rational(4, 2)`, `Rational(1, 2)`, 0.5, 2.0, -1.0 and five boxed ones), in four forms: at top level, through a method, kept in an Array across other allocations, and the answer used in arithmetic. Each run plain, under `SPINEL_GC_STRESS=1` and under 2.

| of 56 | master | this branch |
|---|---|---|
| right | 11 | 32 |
| a line wrong | 45 | 24 |

By the line: 398 right on both, 350 cured, 81 wrong on both, none lost. The 81 are named under **Not here**.

**Cost.** 200,000 powers each, `x ** e` with both boxed (callgrind), master beside this branch:

| | gcc | clang |
|---|---|---|
| an Integer to an Integer | 18,070,781, the same | 15,022,853 to 15,222,853 |
| a Float to an Integer | 73,670,782 to 73,470,782 | 55,023,540 to 55,223,540 |
| a Float to a Float | 73,070,786 to 72,870,786 | 55,823,541 to 56,023,541 |
| an Integer to a Float | 72,870,782 to 72,670,782 | 55,023,540 to 55,223,540 |
| a word-sized Rational to an Integer | 149,352,692, the same | 129,537,697 to 128,937,697 |
| a Bignum to an Integer | 471,140,836, the same | 452,087,121 to 452,287,121 |
| a Complex to an Integer | 76,475,359 to 76,875,359 | 58,064,351 to 59,664,351 |

The new arm sits beside the Complex one under one test of the tag, so a base that is no object does not pass it. Three other spellings were measured: after the Complex arm as a test of its own it costs a Float base 3 with both compilers and a Rational and a Complex base 4 with gcc; the same test marked unlikely costs the same with gcc and a Complex base 3 with clang; folded into the Rational arm it costs a word-sized Rational 13 with gcc and 22 with clang.

**Not here.** Of the family's 81 lines wrong on master and here, 32 have a Rational of Bignums for the base: a negative one to a power that is no Integer (`x ** 0.5`, `x ** Rational(1, 2)`) prints NaN, as every negative boxed base does through `pow(double, double)`, where CRuby answers a Complex (24 lines); one and zero to `Rational(1, 2)` answer 1.0 and 0.0, as the word-sized ones do, where CRuby answers `(1/1)` and `(0/1)` (8 lines). The other 49 have an Integer, a Bignum or a Complex base: a Rational exponent answers a Float, a Bignum to a negative Integer raises RangeError, a Complex to a negative Integer answers Float parts.

A word-sized Rational whose power does not fit a word (`[Rational(2, 3), :a][0] ** 70`) raises RangeError, on master and here. `x ** (2**70)`, a Bignum exponent, answers through Floats as before.

**Generated C.** `make cident REF=3d629868`: `6498 identical, 0 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`. The change is in the runtime; no test's C changes. In `sp_format.o` only the new function differs from master's. Whether optcarrot's generated C changes is not known: there is no checkout of it where this was written.

**Test.** `test/big_rational_pow.rb`: powers 0 to 3 and -1 to -3 of a Bignum numerator, a Bignum denominator and a negative value, Rational exponents that are Integers, the class of the answer, one and zero held as Rationals of Bignums, zero to a negative power, Float and fractional exponents, boxed exponents, the answer used in arithmetic, and powers kept across a loop. On master 36 of its 43 lines are wrong, in every build. Here it prints the same plain, under `SPINEL_GC_STRESS=1` and 2, built with clang, and under `--share-strings`. The `.expected` file is from CRuby 3.3.6 run with `--enable-frozen-string-literal`; 4.0 is not installed where this was written. The test is marked `# spinel: int64`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
