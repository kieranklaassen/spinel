<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A Float digit count that no Integer holds (an infinity, a NaN, a Float past the word) is a RangeError in `round`, `floor`, `ceil` and `truncate` of an Integer or a Float, in Ruby and on master. One site still answers a value: a boxed receiver, in a program where a class defines the method.

```ruby
class Tile
  def floor(d) = "tile"
end
v = [1234, 12.5, Tile.new][0]
[Float::INFINITY, -Float::INFINITY, Float::NAN, 1e30].each do |d|
  p v.floor(d)      # RangeError: float Inf out of range of integer, and so for each
end
```

Master (f5f59352e) prints `0` four times on x86-64, with gcc and with clang, and exits 0.

Beside such a class the call is dispatched on the receiver's class, with the count held in a temporary (`emit_poly_defaults_n`, `src/codegen_poly_plan.c`), and that site wrote the C cast of the temporary itself:

```c
default: _t9 = sp_poly_prec_n(_gcf.v[0], (sp_int)_t10, SP_PREC_FLOOR); break;
```

C leaves the cast undefined for those values. The site now writes `sp_poly_ndigits_f(_gcf.v[0], _t10)` in its place, a helper added beside the two rounding helpers in `lib/spinel_rt.h`:

```c
static SP_INLINE sp_int sp_poly_ndigits_f(sp_RbVal v, sp_float f) {
  if (SP_LIKELY(f >= (sp_float)INTPTR_MIN && f < -(sp_float)INTPTR_MIN)) return (sp_int)f;
  if (sp_poly_numeric_p(v)) sp_float_arg_range_error(f);
  return INTPTR_MIN;
}
```

Where the receiver is an Integer, a Float or a Bignum that is `sp_float_arg_i`, the check `emit_int_expr` writes for a typed Float in an Integer slot everywhere else, with its RangeError and its words. The receiver is asked because the check must not come ahead of another receiver's own answer: a String in such a slot has no `floor`, and `"str".floor(Float::INFINITY)` is a NoMethodError in Ruby and on master, and stays one. For a receiver that is no number, a count no Integer holds reads as the cast read it at run time on x86-64 (`INTPTR_MIN`), now without the cast. A count that is no Float keeps master's C, and a Float count inside the word converts to the Integer it converted to (`v.floor(-1.9)` is `v.floor(-1)`).

Cost: the range test on a Float count at this site, at most 6 instructions a call. callgrind, 200,000 calls each, before and after, with the instructions a call in parentheses (`v` a boxed Integer or Float beside the class, `a` a Float local, `ds` a Float Array, `n` an Integer):

| | gcc | clang |
|---|---|---|
| `v.floor(a)`, `v` a boxed Integer | 10,471,397 to 10,671,400 (+1) | 10,829,348, the same |
| `v.round(ds[i % 3])`, a count read on every call | 28,939,148 to 29,539,147 (+3) | 35,098,641 to 36,298,762 (+6) |
| `v.floor(ds[i % 3])`, `v` a boxed Float | 47,408,477 to 48,141,811 (+4) | 51,566,135 to 52,566,336 (+5) |
| `v.floor(n)` | 11,671,397, the same | 12,029,336, the same |

Where the count does not change in the loop the C compiler lifts the test out of it. The longer line also carries some sites over the size at which master moves a dispatch into a function of its own (320 characters, `pd_hoist`): in a method of 100 such calls, 67 cross that size here and none on master, which costs 10 instructions a call with gcc (15,075,456 to 17,016,223 over 200,000 calls) and nothing with clang (12,033,574 before and after).

No program under `test/`, `benchmark/` and `packages/*/test/` gets other C: the generated C of all 6,751 is master's (three print the path of the build's own directory and differ in that alone), and optcarrot's is byte-identical.

`test/boxed_round_float_digits_beside_class.rb` prints 46 lines: the four methods on a boxed Integer and a boxed Float with `Float::INFINITY`, `-Float::INFINITY`, `Float::NAN` and `10.0 ** 30` as the count; Float counts inside the word, which must keep their answer, on those two and on the class's own object; and a String in the same slot, which must keep its NoMethodError with an infinite count and with one inside the word. On master 32 of its lines differ from Ruby's, with gcc and with clang, exit 0: 24 print a value (`0` or `-9223372036854775808`) and 8 raise a RangeError by chance, with other words. gcc's `-fsanitize=float-cast-overflow` reports the cast at 10 places in it; with this change it reports none, and the test prints its `.expected` in the seven lanes run here (plain, level 1, level 1 with the verifier, level 2, `SPINEL_GC_MINOR=0`, `=1`, and `=1` with `SPINEL_GC_VERIFY_GEN=1` at level 1), gcc and clang, and the same with `--share-strings`.

**Not in this change**, on master and here alike, each beside such a class:

- a boxed count is checked ahead of the receiver: with `d = [Float::INFINITY, 1][0]`, `"str".floor(d)` raises a RangeError where Ruby says NoMethodError;
- a Time with an infinite or NaN count raises an ArgumentError where Ruby raises a RangeError, and a Rational takes a Float count that Ruby refuses with a TypeError. Where such a count is written as a literal, master's answer for those two depended on how the C compiler folded the undefined cast (gcc and clang differ); both now answer as the cast answered at run time. Of the 4,732 lines probed here 22 move by that, each from a wrong value to a raise; none was a right line, and no raise became a value.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this commit on master f5f59352e, built from nothing, on x86-64 with gcc 13.3 and clang 18.1: the test in the seven collector lanes with both compilers, with and without `--share-strings`; `ruby tools/gate.rb check`; the generated C of the 6,751 other programs, unchanged; optcarrot, checksum 59662, its C byte-identical; `make share-strings-test` and `make int-min-test`, both pass; the compiler's own instructions over 1,000 and 2,000 lines of one statement inside a method, before and after: `s += 1 if v.floor(a)` with a Float `a`, 1,112,361,506 and 1,109,065,925 (-0.30%) and 2,213,693,433 and 2,213,505,467 (-0.01%); the same with an Integer count, which keeps master's C, 1,112,186,812 and 1,112,165,602 (-0.00%) and 2,213,314,318 and 2,213,269,256 (-0.00%); a program with no such call, 392,165,844 and 392,168,458 (+0.00%) and 778,359,635 and 778,351,912 (-0.00%). The Float pair's count falls: the longer line carries more sites over the size at which master moves a dispatch into a function (333 of the 1,000 stay inline on master, 33 here), so less text is written.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: none

The `.expected` file was written from ruby 3.3.6 with `--enable-frozen-string-literal`; CRuby 4.0 is not on the machine that ran the checks above, so the first box is left for the gate's run. None of its lines prints a message whose words differ between the two. No value passes 2^31 in the source. optcarrot's generated C did not change. It depends on no other pull request. It neither adds a refusal nor lifts one, so `docs/limitations.md` is as it was.
