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

Master (6271a4f42) prints `0` four times on x86-64, with gcc and with clang, and exits 0.

Beside such a class the call is dispatched on the receiver's class, with the count held in a temporary (`emit_poly_defaults_n`, `src/codegen_poly_plan.c`), and that site wrote the C cast of the temporary itself:

```c
default: _t8 = sp_poly_prec_n(_gcf.v[0], (sp_int)_t9, SP_PREC_FLOOR); break;
```

C leaves the cast undefined for those values. The site now writes

```c
default: _t8 = sp_poly_prec_n_fdigits(_gcf.v[0], _t9, SP_PREC_FLOOR); break;
```

`sp_poly_prec_n_fdigits`, and `sp_poly_round_n_fdigits` for `round`, are added beside the two rounding helpers in `lib/spinel_rt.h`. Each hands the count to its helper through a third, `sp_poly_ndigits_f`:

```c
static SP_INLINE sp_int sp_poly_ndigits_f(sp_RbVal v, sp_float f) {
  if (SP_LIKELY(f >= (sp_float)INTPTR_MIN && f < -(sp_float)INTPTR_MIN)) return (sp_int)f;
  if (sp_poly_numeric_p(v)) sp_float_arg_range_error(f);
  return INTPTR_MIN;
}
static SP_INLINE sp_RbVal sp_poly_round_n_fdigits(sp_RbVal v, sp_float f) { return sp_poly_round_n(v, sp_poly_ndigits_f(v, f)); }
static SP_INLINE sp_RbVal sp_poly_prec_n_fdigits(sp_RbVal v, sp_float f, int op) { return sp_poly_prec_n(v, sp_poly_ndigits_f(v, f), op); }
```

Where the receiver is an Integer, a Float or a Bignum that is `sp_float_arg_i`, the check `emit_int_expr` writes for a typed Float in an Integer slot everywhere else, with its RangeError and its words. The receiver is asked because the check must not come ahead of another receiver's own answer: a String in such a slot has no `floor`, and `"str".floor(Float::INFINITY)` is a NoMethodError in Ruby and on master, and stays one. For a receiver that is no number, a count no Integer holds reads as the cast read it at run time on x86-64 (`INTPTR_MIN`), now without the cast. A count that is no Float keeps master's C, and a Float count inside the word converts to the Integer it converted to (`v.floor(-1.9)` is `v.floor(-1)`).

Cost: the range test on a Float count at this site, at most 13 instructions a call: up to 8 in the rows below, and 13 in one case under them, where master itself moves the dispatch into a function. callgrind, 200,000 calls each, before and after, with the instructions a call in parentheses (`v` a boxed Integer or Float beside the class, `a` a Float local, `ds` a Float Array, `n` an Integer):

| | gcc | clang |
|---|---|---|
| `v.floor(a)`, `a` a constant | 10,470,634 to 10,670,655 (+1) | 10,828,594 and 10,828,567 (0) |
| `v.floor(a)`, `a` known only at run time | 11,274,042 to 12,874,059 (+8) | 11,829,793 to 12,629,817 (+4) |
| `v.round(ds[i % 3])`, a count read on every call | 28,938,399 to 30,338,414 (+7) | 35,097,873 to 36,297,874 (+6) |
| `v.floor(ds[i % 3])`, `v` a boxed Float | 47,407,700 to 48,541,052 (+6) | 51,565,431 to 52,565,449 (+5) |
| `v.floor(n)` | 11,670,634 and 11,670,652 (0) | 12,028,582 and 12,028,555 (0) |

Where the count is a constant the C compiler folds the test away (one instruction is left with gcc). The call the site writes is as long as the cast it replaces, because master moves a dispatch of 320 characters or more into a function of its own (`pd_hoist`) and a longer line would carry sites over that size. In a method of 100 such calls beside a class whose method answers a String none is moved, on master or here, and the generated C is master's but for the helper's name where the cast was: 15,074,616 to 16,077,419, 5 a call, with gcc and 12,032,798 and 12,032,762, nothing a call, with clang, over 200,000 calls. Beside a class whose own method answers an Integer (`def floor(d) = 7`) master itself moves the dispatch of those 100 calls into one function, and here too; the C is again master's but for the helper's name, and the test is paid inside that function. That is the dearest measured: with a count known only at run time, 10,479,607 to 13,079,616, 13 a call, for an Integer receiver and 62,879,607 to 64,479,616, 8 a call, for a Float one with gcc, and 5 a call for each with clang; with a constant count 7 and 2 with gcc and nothing with clang.

The helpers are functions because CONTRIBUTING.md asks it ("Helpers are functions, not Ruby-style macros"). With gcc that is 2 to 4 of the instructions above: written as macros the same test costs 6, 3 and 4 a call in the second, third and fourth rows, where the functions cost 8, 7 and 6 (gcc copies the boxed receiver once more on the way in). With clang the two forms cost the same.

No program under `test/`, `benchmark/` and `packages/*/test/` gets other C: the generated C of all 6,785 is master's (three print the path of the build's own directory and differ in that alone), and optcarrot's is byte-identical.

`test/boxed_round_float_digits_beside_class.rb` prints 46 lines: the four methods on a boxed Integer and a boxed Float with `Float::INFINITY`, `-Float::INFINITY`, `Float::NAN` and `10.0 ** 30` as the count; Float counts inside the word, which must keep their answer, on those two and on the class's own object; and a String in the same slot, which must keep its NoMethodError with an infinite count and with one inside the word. On master 32 of its lines differ from Ruby's, with gcc and with clang, exit 0: 24 print a value (`0` or `-9223372036854775808`) and 8 raise a RangeError by chance, with other words. gcc's `-fsanitize=float-cast-overflow` reports the cast at 10 places in it; with this change it reports none, and the test prints its `.expected` in the seven lanes run here (plain, level 1, level 1 with the verifier, level 2, `SPINEL_GC_MINOR=0`, `=1`, and `=1` with `SPINEL_GC_VERIFY_GEN=1` at level 1), gcc and clang, and the same with `--share-strings`.

**Not in this change**, on master and here alike, each beside such a class:

- a boxed count is checked ahead of the receiver: with `d = [Float::INFINITY, 1][0]`, `"str".floor(d)` raises a RangeError where Ruby says NoMethodError;
- a Time with an infinite or NaN count raises an ArgumentError where Ruby raises a RangeError, and a Rational takes a Float count that Ruby refuses with a TypeError. Where such a count is written as a literal, master's answer for those two depended on how the C compiler folded the undefined cast (gcc and clang differ); both now answer as the cast answered at run time. Of the 5,044 lines probed here 22 move by that, each from a wrong value to a raise; none was a right line, and no raise became a value.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this commit on master 6271a4f42, built from nothing, on x86-64 with gcc 13.3 and clang 18.1: the test in the seven collector lanes with both compilers, with and without `--share-strings`; `ruby tools/gate.rb check`; the generated C of the 6,785 other programs, unchanged; optcarrot, checksum 59662, its C byte-identical; `make share-strings-test` and `make int-min-test`, both pass; the compiler's own instructions over 1,000 and 2,000 lines of one statement inside a method, before and after: `s += 1 if v.floor(a)` with a Float `a`, whose C is master's but for the helper's name where the cast was, 1,127,711,758 and 1,127,431,861 (-0.02%) and 2,244,683,559 and 2,244,173,484 (-0.02%); the same with an Integer count, which keeps master's C, 1,127,554,188 and 1,127,561,177 (+6,989 instructions) and 2,244,173,847 and 2,244,187,836 (+13,989 instructions); a program with no such call, 392,222,122 and 392,222,101 (-21 instructions) and 778,456,339 and 778,456,318 (-21 instructions).

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: none

The `.expected` file was written from ruby 3.3.6 with `--enable-frozen-string-literal`; CRuby 4.0 is not on the machine that ran the checks above, so the first box is left for the gate's run. None of its lines prints a message whose words differ between the two. No value passes 2^31 in the source. optcarrot's generated C did not change. It depends on no other pull request. It neither adds a refusal nor lifts one, so `docs/limitations.md` is as it was.
