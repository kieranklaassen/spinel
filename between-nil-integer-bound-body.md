<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def sm(k, on) = on ? k : nil
n = sm(0, false)
p 2.5 <=> n
p 2.5.between?(n, 3.0)
p 12.between?(20, "a")
```

- Master: `1`, `true`, then ArgumentError (`comparison of Integer with String failed`).
- CRuby and here, each line alone: `nil`, ArgumentError (`comparison of Float with nil failed`), `false`.

Cost, instructions under callgrind for 200,000 compares with an Integer operand that can be nil and changes each turn: against a Float 5,870,456 on master and 6,070,472 here with gcc, one instruction a compare, and 6,637,474 and 6,637,446 with clang; against a Bignum 100,501,515 and 101,101,530 with gcc, 101,458,773 and 102,058,761 with clang, three a compare. With an operand that cannot be nil, none. A `between?` whose bounds compare runs the code it ran, but for one instruction a call with boxed bounds and gcc (200,000 calls: 45,766,078 and 45,966,075; with clang 29,421,732 on both); with typed bounds none: Integer bounds 4,149,318 on both, Float bounds 4,749,318 on both. Compiling, each call site has its own copy of the builtin, so the added lines cost about 0.2 ms and 47 bytes of C a call site.

An Integer local, instance variable or method result that can be nil holds the nil as a sentinel, the Integer -2**63. `<=>` between two Integers tests for it. Against a Float (`sp_int_flt_cmp`) and against a Bignum (`sp_bigint_cmp` on `sp_bigint_new_int`) it did not, so the nil compared as that number and the answer was -1 or 1. `between?` and `clamp` in `builtins/comparable.rb` are written on `<=>`, so with a Float or a Bignum receiver a nil bound was taken for a number: `1.5.between?(1.0, n)` answered `false` and `(2**70).between?(n, 2**72)` `true`.

Now both arms test the sentinel, where the Integer operand can hold it (`cmp_operand_may_be_nil`, which the Integer arm asks). Everywhere else the C is master's. In the Bignum arm the Integer side is kept as it is read and tested after the compare, so the two operands run in the order they ran.

`between?` changes in the same commit, because the first change alone loses programs. CRuby's `Comparable#between?` answers false as soon as the receiver is below min, and does not compare with max then. Master's compared with both bounds before it answered: for a receiver below min and a max that is the nil of an Integer slot, `2.5.between?(5.0, n)`, it answered `false` only because the nil compared as a number, and with the nil read as nil it would raise. So `between?` now answers false below min, as CRuby's does, and with that for any max that cannot be compared: a String, a Symbol, `nil`, an Array, NaN.

What was chosen: the test for "below min" sits in the branch taken when the compare with max fails, not ahead of that compare. Written ahead of the compare, as CRuby has it, the test costs every call (4,449,301 for the Integer bounds).

Not here:

- An Integer slot that holds -2**63 itself reads as nil here too, as it does against an Integer on master: for `n = sm(-9223372036854775807 - 1, true)`, `p 3 <=> n` prints `nil` on master and here, and `p 2.5 <=> n` prints `1` on master and `nil` here. CRuby prints `1` for both.
- `<` and `>` between a Bignum and such a nil: `(2**70) < n` dies with signal 11, on master and here. Against a Float they raise, as in CRuby.
- A Bignum receiver with a bound written `nil`: `(2**70).between?(5, nil)` answers `false` where CRuby raises, on master and here.
- A max that answers `coerce` still has it called when the receiver is below min: `12.between?(Co.new(20), Co.new(30))` calls both `coerce` methods, CRuby the first only. That takes the test ahead of the compare.
- A min whose `coerce` leads to a `<=>` that answers a String: with `Q#<=>` answering `"-5"` and `Cc#coerce` answering `[Q.new, 1]`, `12.between?(Cc.new, nil)` raised with another message on master and answers `false` here, where CRuby raises ArgumentError (`comparison of String with 0 failed`). `12.between?(Cc.new, 30)` answers `false` on master and here: the runtime reads that String as the Integer -5.
- A max of a class with its own `<=>`: `12.between?(20, V.new)` raises NoMethodError, on master and here; CRuby answers `false`.
- A `&.` call with a max written as a literal that cannot compare, `x&.between?(20, "a")`, still raises. Another emitter decides that when it compiles, for a nil `x` too.

Test: `test/between_integer_or_nil_bound.rb`, 64 lines, 55 of output; 24 of the 55 are wrong on master.

Generated C against master (`make cident REF=548d4196def8`): 6470 identical, 16 differ, 0 refusal changes; no compile met cident's time or memory bound. The 16 are the new test and 15 tests that call `between?` on an Integer or a Float or have such a `<=>`: `block_call_arity`, `builtins_comparable`, `comparable_between_user_type`, `int_float_exact_compare`, `issue_2863`, `issue_2893`, `issue_3232`, `nil_recv_compare_nomethod`, `nullable_num_compare`, `numeric_coerce_protocol`, `numeric_nil_argument`, `numeric_string_argument`, `promote_bigint_operands_rooted`, `rand_bignum_bound_literal` and `safe_nav_builtin_scalar`. Each prints the same here as on master with gcc and with clang, plain and under `SPINEL_GC_STRESS=1` and `2`: 13 their `.expected` in all six; `int_float_exact_compare` (gcc) and `numeric_coerce_protocol` (both) differ from it by two lines under `SPINEL_GC_STRESS=2`, on master as here. optcarrot's generated C is byte-identical.

Two sets of small programs, with gcc and with clang, plain and under `SPINEL_GC_STRESS=1` and `2`, measured on 8dc5522541bb, where this change's code is the same. 780 for the nil bound: `between?`, `<=>` on either side and `clamp`, with a Float receiver (six of them, four below -2**63), a Float that may be nil, a Bignum of each sign and an Integer, against an Integer-or-nil bound that is nil and one that is not, read three ways (a call, a local, an `attr_reader`), with seven kinds of other bound. Master is right in all six for 426, this for 777; no program loses a cell. The 3 left are the Bignum line under "Not here". With the `<=>` change alone 66 that master answers right would raise: a receiver below min with a max that is such a nil. 652 for `between?` below min (an Integer local, a Float local, an Integer instance variable and a `&.` call on an Integer that may be nil; ten kinds of min and sixteen of max, typed and boxed; twelve written by hand): 160 have master's C; of the 492 that differ, 346 are right in all six on master and 452 here. The 106 more raised ArgumentError. No program loses a cell, and the 40 left print the same on both.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
