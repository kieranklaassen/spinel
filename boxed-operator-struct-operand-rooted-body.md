<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**A fix with a stated cost.** A boxed operator whose operand is a typed Rational, Complex, Range or Time and whose receiver is another call's answer pays one frame slot, also where something else held that answer: 1.6 instructions a call (`mk(i) + 2r`, 0.2% on the loop measured below). A receiver read from a variable, an Array, a field, a Hash by an Integer or Symbol key, or an Array written in place (`[x, y][0] + 2r`) pays nothing.

A boxed operator could answer for another number in place of its receiver or of its Rational operand. A plain run shows it:

```ruby
def mk(i) = [Rational(i + 1, 3), :a][0]
keep = []
i = 0
while i < 400_000
  v = mk(i) + 2r
  keep << v if i % 2 == 0
  i += 1
end
wrong = []
keep.each_with_index { |v, k| wrong << v unless v == Rational(2 * k + 7, 3) }
p wrong
```

```
spinel diff: output-diff
  program: sums.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-[]
+[(5254/3), (224642/1)]
```

`(5254/3)` stands where `(2633/3)` belongs: it is `mk(2626) + mk(2626)`. Built with clang the one wrong sum is `(4/1)`, which is `2r + 2r`.

A Rational is a struct in C and becomes a heap cell where it is handed to a boxed operator. The node table shows no allocation for a literal `2r` or for a typed local, so the operator arms wrote

```c
lv_v = sp_poly_add(sp_mk(lv_i), sp_box_rational(((sp_Rational){2LL, 1LL})));
```

with neither value held while the other is made. gcc boxes the operand first and the receiver's own allocation can free it; clang makes the receiver first and the box can free it. Under `SPINEL_GC_STRESS=1` the answers come out wrong, and under 2 the mark stops on the freed cell.

The arms already bind the receiver to a rooted temporary when the operand allocates or runs Ruby code (`poly_binop_recv_temp`). `boxed_operand_unholds_recv` adds the case the node table cannot show: the operand's C form is a struct whose box is a cell (a Rational, a Complex, a Range, a Time; a Class value is a struct too and boxes to no cell) and the receiver is not a read. The arithmetic, comparison and `fdiv` arms and `emit_poly_cmp_ordered` then write

```c
lv_v = ({ _gcf.v[0] = sp_mk(lv_i); sp_poly_add(_gcf.v[0], sp_box_rational(((sp_Rational){2LL, 1LL}))); });
```

The receiver is made first and held, and the box is made last, where the operator takes it.

A receiver that is a read keeps its C: a variable, an element read out of an Array, a field (`o.v`), an element of a Hash read by an Integer or Symbol key in a program with no Hash default block (`h[:k] + 2r`), and an element of an Array written in place read by an Integer index that runs no code (`[x, y][0] + 2r`: the literal is built into a rooted temporary ahead of the statement). Each is held where it lives.

**Measured against CRuby 3.3.6 on master 64450fba.** 456 generated programs: eight receivers (a method's answer made each turn, a Bignum made each turn, an Array element made in place, a method that hands its argument back, a local, an Array element, a field, a Hash element) with three operands (`2r`, a typed Rational in a local, `-3r`) under nineteen operators (`+ - * / %`, `< <= > >= == !=`, `<=>`, `eql?`, `divmod`, `quo`, `fdiv`, `div`, `modulo`, `remainder`), six turns each, the answers kept across other allocations and printed.

| of 456 | master | this branch |
|---|---|---|
| right in a plain run, under `SPINEL_GC_STRESS=1` and under 2 | 350 | 436 |
| wrong and silent under `SPINEL_GC_STRESS=1` or 2 | 62 | 0 |
| `SPINEL_GC_STRESS=2`: the mark stops | 24 | 0 |
| wrong in a plain run, two other faults | 20 | 20 |

No program is worse. The 20 are named under **Not here**.

**Cost.** 200,000 calls each (callgrind, gcc):

| | master | this branch |
|---|---|---|
| `x + 2r`, a boxed Rational in a local | 113,877,442 | 113,877,442, the same C |
| `a[0] + 2r`, read out of an Array | 115,477,444 | 115,477,444, the same C |
| `o.v + 2r`, a field | 54,071,215 | 54,071,215, the same C |
| `h[:k] + 2r`, read out of a Hash | 118,677,444 | 118,677,444, the same C |
| `h[:k] + q`, a typed local as the operand | 128,477,459 | 128,477,459, the same C |
| `h[:k] < 2r` | 859,487,784 | 859,487,784, the same C |
| `x < q` | 855,679,731 | 855,679,731, the same C |
| `h[:k].fdiv(2r)` | 32,177,986 | 32,177,986, the same C |
| `h[:k] == 2r` | 47,776,971 | 47,776,971, the same C |
| `[Rational(i + 1, 3), :a][0] + 2r`, an element of an Array written in place | 171,289,469 | 171,289,469, the same C |
| `mk(i) + 2r`, the cured call | 173,027,529 | 173,346,794 |

The last row is the stated cost: the arm cannot tell that something else still holds what a call answered, so it holds the value, as it does when the operand allocates.

**Not here.** `mk(i).clamp(1r, 2r)`: the receiver and both bounds are made inside one C call (`sp_poly_clamp(sp_mk(...), sp_box_rational(...), sp_box_rational(...))`), and under `SPINEL_GC_STRESS=2` the mark stops, on master and here. That is the clamp arm. Of the family, 15 programs put a boxed Bignum beside a Rational (`[2**70, :a][0] + 2r` answers `(2/1)`: the Bignum is read as its low word) and 5 call `fdiv` with a typed Rational local (`x.fdiv(q)` divides the two Floats and prints `1.8666666666666665` for `1.8666666666666667`): both are wrong in a plain run on master and here, and neither is the rooting.

**Generated C.** `make cident REF=64450fba`: `6484 identical, 1 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`. The one is the new test. Whether optcarrot's generated C changes is not known: there is no checkout of it where this was written.

**Test.** `test/boxed_operator_struct_operand_rooted.rb`, also in `GC_STRESS_TESTS`: the five arithmetic operators, a typed local as the operand, `divmod`, `quo`, `fdiv` and `remainder`, five comparisons, and receivers held already (a variable, an Array, a field, a Hash). On master it is right in a plain run, wrong under `SPINEL_GC_STRESS=1` and stops under 2. Here it prints the same plain, at both stress levels with and without `SPINEL_GC_VERIFY=1`, built with clang, and under `--share-strings`; `make gc-stress-test` passes. The `.expected` file is from CRuby 3.3.6 run with `--enable-frozen-string-literal`; 4.0 is not installed where this was written.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
