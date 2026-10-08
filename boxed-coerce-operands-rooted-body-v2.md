<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**A fix with a stated cost.** `x.coerce(y)` on a boxed `x` that is another call's answer (`o.v.coerce(2.5)` through an `attr_reader`) pays one frame slot, 2 instructions a call (0.9% on the loop measured below), also where something else held the value. A receiver read from a variable or out of a variable's Array (`a[0].coerce(2.5)`) pays nothing.

`coerce` on a boxed number could answer with another number in place of an operand made in the argument list. A plain run shows it:

```ruby
r = [3r / 4, :a][0]
keep = []
i = 0
while i < 1000000
  pr = r.coerce(Rational(i, 1))
  keep << pr if i % 4 == 0
  i += 1
end
wrong = []
keep.each_with_index do |pr, j|
  s = pr.inspect
  wrong << s if s != "[(#{j * 4}/1), (3/4)]"
end
p wrong
```

```
spinel diff: output-diff
  program: coerce.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-[]
+["[(2178/1), (3/4)]"]
```

`sp_poly_coerce` allocates the Array it answers with before it stores its operands. A Rational or a Bignum handed over boxed is a cell, and one made in the argument list is held by nothing while that Array is made:

```c
lv_pr = sp_poly_coerce(lv_r, sp_box_rational(/* Rational(i, 1) */));
```

A collection on the Array frees the cell and a later Rational takes its place. Under `SPINEL_GC_STRESS=1` the pairs come out wrong, and under 2 the mark stops on the freed cell.

The pair keeps the operands themselves, so the call holds them. The two arms that write `sp_poly_coerce` (a boxed receiver; an Integer receiver with a boxed operand) bind a value that nothing else holds to a rooted temporary, as the Bignum receiver's arm does already and as a call does for its arguments (`arg_wants_root`):

```c
lv_pr = ({ sp_RbVal _t2 = lv_r; _gcf.v[0] = sp_box_rational(/* Rational(i, 1) */); sp_poly_coerce(_t2, _gcf.v[0]); });
```

A typed Rational is a struct in C and is copied into a new cell where it is boxed, so its box is made in the argument list also when the value is read from a variable, a parameter or a constant: with `q = Rational(i, 1)` and `pr = r.coerce(q)` the program above prints the same wrong pair on master. That box is held too.

A read of a boxed variable, an Integer and a Float keep their C. So does an element read out of a variable's Array of boxed values by an index that runs no code (`a[0].coerce(2.5)`): the Array holds it, the operand is read last, and a receiver read that way is held as long as the operand runs no code either.

**Measured against CRuby 3.3.6 on master 42557a3c.** 189 generated programs: `coerce` on seven boxed receivers (a Rational, an Integer, a Float and a Bignum read from a local; a Rational, a Bignum and a Rational of Bignums made in place) with nine operands (`2r`, a Rational made by `Rational`, a Rational sum, an Integer, a Float, a Bignum, and a Rational, a Bignum and an Integer read from an Array), the pair printed, kept across other allocations, and indexed.

| of 189 | master | this branch |
|---|---|---|
| right in a plain run, under `SPINEL_GC_STRESS=1` and under 2 | 126 | 189 |
| `SPINEL_GC_STRESS=2`: wrong and silent | 45 | 0 |
| `SPINEL_GC_STRESS=2`: the mark stops | 18 | 0 |

308 more, for an operand that is a typed value read from a variable: eleven receivers (boxed values read from a local, made each turn, made in place, read through a reader and out of an Array, and plain Integers) with seven operands (a typed Rational in a local, a constant, in parentheses, an instance variable and a parameter; a Bignum and a Float in a local), the pair inspected at once or kept across other allocations, at top level and inside a method.

| of 308 | master | this branch |
|---|---|---|
| right in a plain run, under `SPINEL_GC_STRESS=1` and under 2 | 112 | 308 |
| `SPINEL_GC_STRESS=2`: wrong and silent | 72 | 0 |
| `SPINEL_GC_STRESS=2`: the mark stops | 96 | 0 |
| `SPINEL_GC_STRESS=1`: wrong and silent, and the mark stops under 2 | 28 | 0 |

**Cost.** 200,000 calls each (callgrind, gcc):

| | master | this branch |
|---|---|---|
| `r.coerce(i)`, a boxed Rational in a local | 67,784,789 | 67,784,789, the same C |
| `a[0].coerce(2.5)`, a receiver read out of an Array | 45,985,060 | 45,985,060, the same C |
| `r.coerce(Rational(i, 1))`, the cured call | 69,696,643 | 70,892,136 |
| `q = Rational(i, 1); r.coerce(q)`, cured the same way | 69,696,643 | 70,892,136 |
| `o.v.coerce(2.5)`, a receiver that is a call's answer | 45,228,416 | 45,641,433 |

The last row is the stated cost: the call cannot tell that the object still holds what its reader answered, so it holds the value, as a call holds such an argument. A typed Rational `coerce` is the same C.

**Not here.** `r.coerce(Complex(1, 2))` raises TypeError where CRuby answers a pair, and a typed Rational's `coerce` of a boxed Rational raises NoMethodError, on master and here. `mk(i) + 2r`, where `def mk(i) = [Rational(i + 1, 3), :a][0]`: the literal is boxed in the argument list beside a receiver made in place, and neither is held while the other is made. Under `SPINEL_GC_STRESS=2` it answers for the wrong operand (`(4/3)` for `(7/3)`) on master and here. That is the operator arm, for every operator.

**Generated C.** `make cident REF=42557a3c`: `6468 identical, 2 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`. The two are the new test and `boxed_rational_coerce` (which stops under `SPINEL_GC_STRESS=2` on master and passes here). `bignum_coerce_float`, whose `a[0].coerce(2.5)` is the element read above, is the same C. Whether optcarrot's generated C changes is not known: there is no checkout of it where this was written.

**Test.** `test/boxed_coerce_operands_rooted.rb`, also in `GC_STRESS_TESTS`: an operand made in the argument list, a receiver made in place, both, a typed Rational read from a local, a parameter and a constant, an element read out of a variable's Array until the operand's code puts another in its place, and operands held already. On master it is wrong under `SPINEL_GC_STRESS=1` and stops under 2. Here it prints the same plain, at both stress levels with and without `SPINEL_GC_VERIFY=1`, built with clang, and under `--share-strings`; `make gc-stress-test` passes. The `.expected` file is from CRuby 3.3.6 run with `--enable-frozen-string-literal`; 4.0 is not installed where this was written. The test is marked `# spinel: int64` and prints Arrays of Integers, Floats, Rationals and Bignums.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
