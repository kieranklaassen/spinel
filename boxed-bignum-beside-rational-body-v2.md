<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A Bignum beside a Rational, both read out of a container, gave a wrong answer in a plain run:

```ruby
b = [2**70, :a][0]
q = [Rational(2, 5), :a][0]
p b + q
p q - b
p b * q
p b / q
```

```
spinel diff: output-diff
  program: big.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,4 +1,4 @@
-(5902958103587056517122/5)
-(-5902958103587056517118/5)
-(2361183241434822606848/5)
-(2951479051793528258560/1)
+(2/5)
+(2/5)
+(0/1)
+(0/1)
```

`q / b` raised `ZeroDivisionError`. The typed spelling `2**70 + Rational(2, 5)` is refused ("unsupported arithmetic"), so only the boxed operators answer.

The Rational arm of `sp_poly_add`, `sp_poly_sub`, `sp_poly_mul` and `sp_poly_div` (lib/spinel_rt.h) read each operand through `sp_poly_as_rational`, which reads anything that is not a Rational as an Integer of one word. A Bignum read that way is 0. Only an operand that was already a Rational of Bignums took the arm that handles a Bignum (`sp_brat_add_poly` and its three sisters).

The arm now reads its two operands itself (`SP_POLY_RAT_OPERAND`) and hands a Bignum to that arm, which answers a Rational of Bignums. A Rational beside a Rational, an Integer or a Float takes the path it took.

**Measured against CRuby 3.3.6 on master 8dc55225.** 800 generated programs: `x + y`, `x - y`, `x * y` and `x / y` for every ordered pair of ten values read out of an Array (three Bignums, a Rational, a negative Rational, a Rational of Bignums, an Integer, a Float, zero and a zero Rational), the answer printed, and kept across other allocations in a loop.

| of 800 | master | this branch |
|---|---|---|
| right in a plain run, under `SPINEL_GC_STRESS=1` and under 2 | 676 | 800 |
| wrong in a plain run | 124 | 0 |

**Cost.** None. 200,000 operations each, both operands read out of an Array (callgrind, gcc):

| | master | this branch |
|---|---|---|
| a Rational plus a Rational | 122,524,517 | 121,124,510 |
| a Rational times an Integer | 121,717,168 | 121,717,168 |
| an Integer minus a Rational | 141,717,907 | 141,317,905 |
| a Rational divided by a Rational | 134,925,078 | 134,526,204 |
| a Rational plus a Float | 59,074,529 | 59,074,529 |

**Not here.** The same pair is wrong in other functions, on master and here: `b.quo(q)` prints `(0/1)`, `q.quo(b)` raises `ZeroDivisionError`, and `quo` on a Rational of Bignums raises `RangeError`; `%`, `divmod`, `modulo` and `remainder` are wrong for a Rational of Bignums beside a Float; `fdiv` of a Rational by a Rational of Bignums differs in the last digit.

**Generated C.** `make cident REF=8dc55225`: `6447 identical, 0 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`. The change is in the runtime header alone, so no program's C moves. Whether optcarrot's generated C changes is not known: there is no checkout of it where this was written.

**Test.** `test/boxed_bignum_beside_rational.rb`: a Bignum then a Rational and a Rational then a Bignum for the four operators, with both signs; answers that go on into another operation and into `==`, `>` and `<`; a loop that keeps its answers; and the pairs that were right before (an Integer, a Rational or a Float beside a Rational, a Bignum beside an Integer or a Float, division by a boxed zero). On master its first eight answers are wrong in a plain run and the ninth raises `ZeroDivisionError`. Here it prints the same plain, at both stress levels with and without `SPINEL_GC_VERIFY=1`, built with clang, and under `--share-strings`. The `.expected` file is from CRuby 3.3.6 run with `--enable-frozen-string-literal`; 4.0 is not installed where this was written. The test is marked `# spinel: int64`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
