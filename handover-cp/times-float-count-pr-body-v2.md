<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A String or an Array out of a mixed container, times a Float, raised TypeError where Ruby repeats by the truncated count:

```ruby
row = ["ab", [1, 2]]
n = [2.5, :k][0]
p row[0] * n          # TypeError: no implicit conversion of Float into String; Ruby prints "abab"
p row[1] * n          # TypeError: ... into Array; Ruby prints [1, 2, 1, 2]

width = { cols: 7, fill: "-" }
puts width[:fill] * (width[:cols] / 2.0)   # the same TypeError; Ruby prints ---
```

The count of `String#*` and `Array#*` is an Integer argument, and a Float there is truncated. A typed String already answers so, also for a boxed count. For a boxed receiver `sp_poly_mul` has arms for an Integer count alone; a Float fell to `sp_poly_binop_bad`, which words it as an operand `String#+` cannot convert.

The last line of `sp_poly_mul`, where no arm has an answer, now calls `sp_poly_times_tail` in place of the bad-operand report. There a String or an Array with a Float count is truncated toward zero and goes back into `sp_poly_mul` with the Integer count; every other pair is the report it was. The Integer arms do the work, so a negative count is ArgumentError as a negative Integer is. NaN, an infinity or a Float past the word is RangeError in Ruby's words (`float NaN out of range of integer`), checked before the cast, which is undefined for those. A count past the length an Array can have is ArgumentError (`argument too big`); the Integer count's arm would fill memory before it found out. It holds for every way to the operator: `*=` on a local, an attribute or an element, `send`, `inject(:*)`.

No pair that had an answer pays. `sp_poly_mul` gains no test, only another callee on its failing last line (the one existing line of `lib/spinel_rt.h` that changes), and the new function is not inlined, so the arms that answer are the code they were: 0 instructions a call with gcc and with clang on Integer, Float and mixed pairs, a String or an Array times an Integer, the Array join, a Bignum, a Rational, an object's own `*`, and on loops that mix the boxed operators (callgrind, master 759d120f). A test ahead of that line, in each of the three places tried, moved gcc's layout of the function by an instruction or more on some pair.

A boxed `*` reaches no String's or Array's own `*`: with an Integer count the builtin answers whatever the program defines. So in a program that has a method named `*` of its own, in any class or module or on one object, a Float count keeps its TypeError: the builtin's repeat must not stand where the program's method was meant. The generated unit of such a program sets one static flag in its init (15 corpus programs gain that line; every other program's C is unchanged).

Not covered: a typed Array times a typed Float (NoMethodError); through a boxed receiver, a count that is a Rational, a Complex or an object with `to_int` (TypeError, as before), and the words of the TypeError for nil, a Symbol or true ("into String" where Ruby says "into Integer"). A fold whose count is a typed Float, `[s, 2.5].inject(:*)`, still raises: master types the fold's value a Float, and the String the multiply now answers does not convert (ArgumentError where it was TypeError; with a typed Integer count master prints 0 there). The same boxed String divided by a number (`row[0] / 2` prints 0 where Ruby raises NoMethodError) is not here either: the change that makes a boxed `/` or `%` beside a value that is no number raise cures it.

Of the three tests, the first prints 32 wrong lines on master and the 64-bit one a TypeError for the ArgumentError; the third, a strict `String#*` of the program's own, is right on master and guards the stand-down. Optcarrot's generated C is unchanged. Its run moves by 0.002% with gcc and 0.001% with clang (3,230,992,860 to 3,231,060,468 and 2,750,486,969 to 2,750,522,665 instructions; checksum 59662), all of it in `sp_PolyPolyHash_get`, which the change does not touch; `sp_poly_mul` runs the same count there.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (test/poly_times_float_count_big.rb)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
