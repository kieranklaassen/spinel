<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**A fix with a cost.** A Float digit count that no Integer holds (an infinity, a NaN, a Float past the word) is a RangeError in Ruby. In `round`, `floor`, `ceil` and `truncate` the answer followed the C compiler and the machine instead. The cost is a range test on a Float count, at most 8 instructions a call; the table is below.

```ruby
p 42.round(Float::INFINITY)    # RangeError: float Inf out of range of integer
p 42.round(-Float::INFINITY)   # RangeError: float -Inf out of range of integer
p 42.round(Float::NAN)         # RangeError: float NaN out of range of integer
```

| master, the three lines | |
|---|---|
| gcc 13.3, x86-64 | a RangeError each, by chance and with other words: "integer -9223372036854775808 too small to convert to 'int'" |
| clang 18.1, x86-64 | 42, 42, 42 |
| Apple clang, arm64 | 42, 42, 42: ruby/spec's `core/integer` round case fails there in `make gate` |

A typed Float in an Integer slot is written as a C cast (`emit_int_expr`, `src/codegen.c`):

```c
sp_int_round(42LL, (sp_int)((1.0/0.0)))
```

C leaves that cast undefined for an infinity, a NaN and a Float past the word. x86-64's instruction answers the smallest Integer, which `round`'s own check of the count happens to refuse; arm64's answers the nearest end of the word and 0 for a NaN; a compiler that folds the cast of a constant answers anything. gcc's `-fsanitize=float-cast-overflow` reports the cast three times on those three lines and 32 times on the new test; with this change it reports none.

Only `round` on an Integer checks its count, so the other forms answered a value on master (`n = 42`, `f = 42.5`, `x = 2 ** 70`, `v` an Integer in a boxed slot, `inf` and `nan` locals; x86-64):

| | Ruby | master, gcc | master, clang |
|---|---|---|---|
| `n.floor(inf)`, `n.ceil(-inf)`, `n.truncate(nan)` | RangeError | 0 | 42 |
| `n.round(inf, half: :even)` | RangeError | the RangeError of the three lines | RangeError "integer 93859771622896 too big to convert to 'int'", another number each run |
| `f.round(inf)`, `f.floor(nan)` | RangeError | -9223372036854775808 | a RangeError with no message |
| `x.round(inf)`, `v.round(inf)` | RangeError | the RangeError of the three lines | the one with another number each run |
| `v.floor(nan)` | RangeError | 0 | 42 |

`sp_float_to_ndigits` (`lib/spinel_rt.h`) reads a Float count as CRuby's `NUM2LONG` does: its integer part inside the word, and CRuby's RangeError outside it, in CRuby's words. It stands where the cast stood at the digit count of the four methods, wherever CRuby reads the count that way: an Integer, a Bignum, a Float and a boxed receiver, with and without `half:`. One function, `float_ndigits` (`src/codegen.c`), asks whether a count is a Float the cast would be written for; for any other count the generated C is master's.

On an Integer, a Float and a boxed receiver the count is converted where Ruby converts it, after the receiver and the keywords' values have run:

```ruby
def recv = (puts "recv"; 1234)
recv.round(Float::INFINITY)                          # prints recv, then raises
1234.round(Float::NAN, half: (puts "half"; :even))   # prints half, then raises
```

so an Integer or a boxed receiver is read into a temp ahead of a Float count (C does not order a call's arguments).

What keeps its answer and what it costs. A Float count inside the word converts to the Integer it converted to (`1234.round(-1.9)` is `1234.round(-1)`), and pays the range test: two compares, which the C compiler drops where it can see the count and lifts out of a loop where the count does not change. A Float literal a 32-bit word holds (`n.round(-2.0)`) and a count that is no Float keep master's C. callgrind, 200,000 calls each, before and after, with the instructions a call in parentheses (`a` a Float local, `ds` a Float Array):

| | gcc | clang |
|---|---|---|
| `(n + i).round(a)` | 10,764,642 to 10,764,689 (+0) | 10,923,592 to 10,923,852 (+0) |
| `(n + i).floor(a)` | 8,824,642 to 8,824,653 (+0) | 8,983,592 to 8,983,879 (+0) |
| `(n + i).round(a, half: :even)` | 11,784,727 to 11,784,735 (+0) | 11,943,652 to 12,343,907 (+2) |
| `x.round(a)`, `x` a Bignum | 1,209,193,038 to 1,209,993,035 (+4) | 1,204,915,645 to 1,204,916,018 (+0) |
| `(f + i).round(a)`, `f` a Float | 39,068,928 to 38,668,940 (-2) | 37,825,922 to 37,825,956 (+0) |
| `v.round(a)`, `v` an Integer in a boxed slot | 33,269,908 to 33,669,915 (+2) | 5,426,044 to 6,026,211 (+3) |
| `(n + i).round(ds[i % 3])`, a count read on every call | 12,330,603 to 13,330,638 (+5) | 13,889,752 to 14,489,807 (+3) |
| `(f + i).round(ds[i % 3])` | 48,468,121 to 49,534,795 (+5) | 48,559,088 to 48,959,165 (+2) |
| `v.round(ds[i % 3])` | 27,402,584 to 29,002,580 (+8) | 9,692,034 to 10,692,210 (+5) |
| `(n + i).round(-2.0)` | 11,650,774, the same | 11,807,490, the same |
| `(n + i).round(d)`, `d` an Integer | 10,250,774, the same | 10,607,490, the same |

No program under `test/`, `benchmark/` and `packages/*/test/` gets other C: the generated C of all 6,729 is master's, and optcarrot's is byte-identical.

`test/round_float_digits_range.rb` has 65 lines: the three above, the four methods with `Float::INFINITY`, `-Float::INFINITY`, `Float::NAN` and `10.0 ** 30` as literals and as locals, on an Integer, a Bignum, a Float and a boxed receiver, with `half:`, with a receiver and a keyword value that print, and Float counts inside the word that must keep their answer. On master 30 of its lines differ from Ruby's with gcc and 30 with clang, with exit 0. With this change it prints its `.expected` in the seven lanes run here (plain, level 1, level 1 with the verifier, level 2, `SPINEL_GC_MINOR=0`, `=1`, and `=1` with `SPINEL_GC_VERIFY_GEN=1` at level 1), gcc and clang, and the same with `--share-strings`.

**Not in this change**, on master and here alike:

- A count past a C int in `floor`, `ceil` and `truncate`, and in all four on a Float receiver, is not checked, whatever its class: `1234.floor(1e10)` answers 1234 where Ruby raises "integer 10000000000 too big to convert to 'int'", and `1234.floor(2 ** 40)` does the same.
- A Rational receiver: Ruby raises TypeError "not an integer" for any Float count, inside the word or not. That is a check of the count's class.
- A count held in a boxed slot (`ds = [Float::INFINITY, 2]`, `n.round(ds[0])`) is read by the runtime, not by this cast: an infinity raises there in other words and a NaN is cast.
- With gcc a Bignum receiver's count raises before a receiver that prints has run; a Float receiver is read after its count has run (`f.round((f = 2.5; a))`). Both are master's order, for any count.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this commit on master b79108103, built from nothing, on x86-64 with gcc 13.3 and clang 18.1: the test in the seven collector lanes with both compilers, with and without `--share-strings`; `ruby tools/gate.rb check`; the generated C of the 6,729 other programs, unchanged; optcarrot, checksum 59662, its C byte-identical; `make share-strings-test` and `make int-min-test`, both pass; the compiler's own instructions over 1,000 and 2,000 lines of one statement, before and after: `s += n.round(d)` with an Integer `d`, which keeps master's C, 1,123,588,686 and 1,123,918,042 (+0.03%) and 2,246,589,661 and 2,247,219,836 (+0.03%); `s += n.round(a)` with a Float `a`, 1,122,659,053 and 1,131,389,854 (+0.78%) and 2,245,497,369 and 2,260,354,670 (+0.66%); `s += 1 if f.round(a)` on a Float `f`, 874,407,366 and 881,796,936 (+0.85%) and 1,749,280,252 and 1,763,756,644 (+0.83%); a program with no such call, 808,171,692 and 808,150,062 (-0.00%).

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: none

The `.expected` file was written from ruby 3.3.6 with `--enable-frozen-string-literal`; CRuby 4.0 is not on the machine that ran the checks above, so the first box is left for the gate's run. None of its lines prints a message whose words differ between the two. The test has a Bignum and carries `# spinel: int64`. optcarrot's generated C did not change. It depends on no other pull request.
