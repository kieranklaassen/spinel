<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A Bignum `==` or `!=` a value known only at run time read the value as a Bignum, so a zero Bignum was `==` nil.

Cost, on the two pairs master had right: a Bignum against a boxed Integer or a boxed Bignum takes master's two tests first and in master's order, and costs 0 to 2 instructions a comparison where the boxed value changes from one comparison to the next (`g == vs[i & 1]`), and 6 to 8 built with gcc and 2 to 3 built with clang in a loop whose boxed value never changes. There the compiler lifted master's read of the tag out of the loop and does not lift it out of the longer function. Five other shapes of the two functions were measured (the rest out of line, the whole out of line, master's two calls kept with a test before them) and none is cheaper.

```ruby
total = 2**64
total -= 2**64
row = [nil, "paid", 3.7]
p total == row[0]
p total == row[1]
puts "nothing owed" if total == row[0]
three = total + 3
p three == row[2]
p row.count { |v| total == v }
```

Master (9274c732e) prints `true`, `true`, `nothing owed`, `true`, `2`, built with gcc and with clang. CRuby prints `false`, `false`, `false`, `0`.

Where one side of `==` or `!=` is typed a Bignum and the other is boxed, the two were compared by `sp_bigint_cmp` with the box read through `sp_poly_as_bigint`. That answers 0 for a value that is not an Integer, a Bignum or a Float, and truncates a Float: a zero Bignum was `==` nil, a String, a Symbol, an Array and false; a Bignum 3 was `==` 3.7; `2**70` was `!=` the Float of the same value.

The pair now goes to `sp_bigint_eq_poly`, or to `sp_poly_eq_bigint` with the box on the left, two inline functions added to `lib/spinel_rt.h`. Their first two tests are the boxed Bignum and the boxed Integer, read as they were. nil, a String, a Symbol, true and false equal no Bignum. An object of the program is asked its own `==`, as Bignum#== hands an operand that is no number back to it; a class with no `==` answers false. A Float or a builtin object is asked by `sp_poly_eq`. Lines are added only: 20 in the header, 20 in `src/codegen_call.c` (a new function of 12 lines and one line in `emit_case_eq_call`, 725 lines to 726). Two Bignums, and a Bignum against an Integer or a Float typed as one, keep the C they had. The ordering operators are not touched.

`box != bignum` keeps the read it had in a program where a class defines a `!=` of its own: the pair would answer for an object of that class by negating its `==`, and the boxed path calls no `!=` of the program's. In such a program `bignum != box` and both `==` are answered as above.

Not in this change, each wrong on master and the same here: a Bignum 3 `==` a boxed `Complex(3, 0)` is false; `eql?` and `equal?` with a typed Bignum receiver are refused; an Integer or a Float `==` a boxed object of the program still answers false without asking the object, which is a pull request of its own; `big < nil` prints false and `big <=> :sym` prints 1; a variable typed a Bignum that holds nil segfaults against a boxed Integer or a boxed Bignum (against nil, a String, a Float or an object it now answers); a boxed object's own `!=` is not called. Under `SPINEL_GC_STRESS=2`, built with gcc, `alloc(row, 4) == (big * 3)` with a boxed Float on the left stops on the mark path where master prints a wrong `false`; the same shape with a boxed Bignum is wrong under `SPINEL_GC_STRESS=1` on master and here.

`make cident` against master: 6414 identical, 7 differ: the two new tests and 5 tests of the corpus (`test/bigint_poly_container.rb`, `test/kernel_conv_protocol.rb`, `test/multi_assign_operand_gc_root.rb`, `test/poly_bitop_recv_root.rb`, `test/promote_bigint_toom3_negative_eval.rb`), by the comparison and no other line. Each does what it does on master, plain and under `SPINEL_GC_STRESS=2`: three print their `.expected` in both; `test/multi_assign_operand_gc_root.rb` prints it in a plain run and stops under stress, before and after; `test/promote_bigint_toom3_negative_eval.rb`, a test of `--int-overflow=promote`, raises RangeError without the flag, before and after.

1,235 programs, each against CRuby. 875: five Bignums on the left (zero, 3, `2**70`, a negative one, a product of two Integers) by 25 boxed values (nil, true, false, a Symbol, Strings, Arrays, a Hash, a Range, Integers, Floats with NaN and the Float of `2**70`, Bignums, Rationals, `Complex(3, 0)`, objects with and without `==`) by `==`, `!=`, a condition and a block, an instance variable, a parameter, and `==` and `!=` with the boxed value first. 180 more put the pair in `===`, a `case`, `include?` and `index`, `uniq`, `eql?` and `equal?`. 676 are right before and after, 137 wrong before and right now, 7 wrong before and after (`Complex(3, 0)`), 175 raise RangeError before and after (the product overflows before the comparison) and 60 are refused before and after (`eql?`, `equal?`). None that was right is otherwise. 180 more put a class with a `!=` of its own in the program (alone, with `==`, inherited, from a module, one that prints, and a class the operand is not of), on both sides of `==` and `!=`: 79 are right before and after, 76 wrong before and right now, and 25 wrong before and after, each a `box != bignum` kept as it was.

Cost under callgrind, 200,000 comparisons, instructions a comparison before and after:

| the pair | gcc 13.3 | clang 18.1 |
|---|---|---|
| Bignum `==` boxed Integer, the box changes | 502 and 503 | 501 and 503 |
| boxed Integer `!=` Bignum, the box changes | 504 and 506 | 499 and 501 |
| Bignum `==` boxed Bignum, the box changes | 66 and 67.5 | 73 and 75 |
| boxed Bignum `!=` Bignum, the box changes | 66 and 66 | 71 and 72.5 |
| Bignum `!=` boxed Integer, one box | 490 and 497 | 487 and 489 |
| boxed Integer `!=` Bignum, one box | 488 and 494 | 482 and 485 |
| Bignum `==` boxed Bignum, one box | 59 and 67 | 63 and 65 |

Two typed Bignums, and a Bignum against a typed Integer or Float, cost the same to the instruction. The pairs master answered wrong, with gcc: a boxed String 198 and 22; an object with no `==` 198 and 94; an object with `==` 198 and 812, the call; a boxed Float 499 and 6,167, where the typed pair costs 5,971.

Tests: `test/bignum_eq_boxed_value.rb`, 16 lines, master is wrong in 14; `test/bignum_ne_boxed_own_ne.rb`, 4 lines, master is wrong in 3 and `box != bignum` prints what it printed.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
