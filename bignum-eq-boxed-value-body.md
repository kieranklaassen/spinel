<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A Bignum `==` or `!=` a value known only at run time read the value as a Bignum, so a zero Bignum was `==` nil.

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

Master (d02a49fb7) prints `true`, `true`, `nothing owed`, `true`, `2`, built with gcc and with clang. CRuby prints `false`, `false`, `false`, `0`.

Where one side of `==` or `!=` is typed a Bignum and the other is boxed, the two were compared by `sp_bigint_cmp` with the box read through `sp_poly_as_bigint`. That answers 0 for a value that is not an Integer, a Bignum or a Float, and truncates a Float: a zero Bignum was `==` nil, a String, a Symbol, an Array and false; a Bignum 3 was `==` 3.7; `2**70` was `!=` the Float of the same value.

The pair now goes to `sp_bigint_eq_poly`, or to `sp_poly_eq_bigint` with the box on the left, two inline functions added to `lib/spinel_rt.h`. Their first two tests are the boxed Bignum and the boxed Integer, read as they were. nil, a String, a Symbol, true and false equal no Bignum. An object of the program is asked its own `==`, as Bignum#== hands an operand that is no number back to it; a class with no `==` answers false. A Float or a builtin object is asked by `sp_poly_eq`. Lines are added only: 20 in the header, 16 in `src/codegen_call.c` (a new function of 9 lines and one line in `emit_case_eq_call`, 725 lines to 726). Two Bignums, and a Bignum against an Integer or a Float typed as one, keep the C they had. The ordering operators are right on master and are not touched.

Not in this change, each wrong on master and the same here: a Bignum 3 `==` a boxed `Complex(3, 0)` is false; `eql?` and `equal?` with a typed Bignum receiver are refused; an Integer or a Float `==` a boxed object of the program still answers false without asking the object, which is a pull request of its own.

`make cident` against master: 6399 identical, 6 differ: the new test and 5 tests of the corpus (`test/bigint_poly_container.rb`, `test/kernel_conv_protocol.rb`, `test/multi_assign_operand_gc_root.rb`, `test/poly_bitop_recv_root.rb`, `test/promote_bigint_toom3_negative_eval.rb`), by the comparison and no other line. Each prints its `.expected` in a plain run and does under `SPINEL_GC_STRESS=2` what it does on master.

1,055 programs, each against CRuby. 875: five Bignums on the left (zero, 3, `2**70`, a negative one, a product of two Integers) by 25 boxed values (nil, true, false, a Symbol, Strings, Arrays, a Hash, a Range, Integers, Floats with NaN and the Float of `2**70`, Bignums, Rationals, `Complex(3, 0)`, objects with and without `==`) by `==`, `!=`, a condition and a block, an instance variable, a parameter, and `==` and `!=` with the boxed value first. 180 more put the pair in `===`, a `case`, `include?` and `index`, `uniq`, `eql?` and `equal?`. 676 are right before and after, 137 wrong before and right now, 7 wrong before and after (`Complex(3, 0)`), 175 raise RangeError before and after (the product overflows before the comparison) and 60 are refused before and after (`eql?`, `equal?`). None that was right is otherwise.

Cost under callgrind, built by gcc 13.3 at `-O2`, 200,000 comparisons in `g = 2**70; 200_000.times { n += 1 if g != b }`, instructions before and after: two typed Bignums, 11,076,120 and the same; a Bignum and a typed Integer, 96,702,078 and the same; a boxed Integer, 97,901,698 and 99,304,713 (+1.4%); a boxed Bignum, 11,880,878 and 13,483,891 (8 instructions a comparison, +13.5%); a boxed value `!=` a Bignum, 97,501,712 and 98,704,726 (+1.2%); a boxed String, 39,501,223 and 4,475,141; a boxed object with no `==`, 39,504,575 and 18,878,287; a boxed object with `==`, 39,508,237 and 162,308,721, the call. A Bignum `==` the boxed Float of the same value answered false in 99,701,598 instructions and answers true in 1,233,307,763: a wrong answer made right by `sp_bigint_eq_f`, the exact comparison a Bignum against a typed Float already gets (1,194,100,047 for that pair, before and after).

Test: `test/bignum_eq_boxed_value.rb`, 16 lines; master is wrong in 14.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
