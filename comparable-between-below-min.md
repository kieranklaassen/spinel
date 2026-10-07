<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
p 12.between?(20, "a")
p 1.5.between?(2.0, Float::NAN)
```

- Master: `ArgumentError` for each (`comparison of Integer with String failed`).
- CRuby: `false`, `false`.

CRuby's `Comparable#between?` answers false as soon as the receiver is below min, and does not compare with max then. `between?` in `builtins/comparable.rb`, which an Integer or Float receiver uses, compared with both bounds before it answered, and raised for a max that cannot be compared: a String, a Symbol, `nil`, an Array, NaN, a local that is sometimes nil.

Now it answers false there.

What was chosen: the test for "below min" sits in the branch taken when the compare with max fails, not ahead of that compare. So a call whose bounds compare runs the code it ran. Instructions under callgrind for 200,000 calls, master then here: Integer bounds 4,149,318 and 4,149,304; Float bounds 4,749,318 and 4,749,304; boxed bounds 45,766,078 and 45,966,061 with gcc, one instruction a call, and 29,421,732 and the same with clang. Written ahead of the compare, as CRuby has it, the test costs every call (4,449,301 for the Integer bounds).

Not here:

- A max that answers `coerce` still has it called when the receiver is below min: `12.between?(Co.new(20), Co.new(30))` calls both `coerce` methods, CRuby the first only. That takes the test ahead of the compare.
- A `&.` call with a max written as a literal that cannot compare, `x&.between?(20, "a")`, still raises. Another emitter decides that when it compiles, for a nil `x` too.

Test: `test/comparable_between_stops_at_min.rb`, 19 lines; 10 of them raise on master.

Generated C against master (`make cident REF=9274c732eaa2`): 6404 identical, 15 differ, 0 refusal changes. The 15 are the new test and 14 tests that call `between?` on an Integer or a Float: `block_call_arity`, `builtins_comparable`, `comparable_between_user_type`, `issue_2863`, `issue_2893`, `issue_3232`, `nil_recv_compare_nomethod`, `nullable_num_compare`, `numeric_coerce_protocol`, `numeric_nil_argument`, `numeric_string_argument`, `promote_bigint_operands_rooted`, `rand_bignum_bound_literal` and `safe_nav_builtin_scalar`. Each of the 14 prints what it prints on master, with gcc and with clang, plain and under `SPINEL_GC_STRESS=1` and `2` (`numeric_coerce_protocol` is wrong under stress 2 on both). optcarrot's generated C is byte-identical.

652 small programs written for this change (an Integer local, a Float local, an Integer instance variable and a `&.` call on an Integer that may be nil; ten kinds of min and sixteen of max, typed and boxed; twelve written by hand), with gcc and with clang, plain and under `SPINEL_GC_STRESS=1` and `2`: 415 are right in all six on master, 521 here. The 106 more raised ArgumentError. No program loses a cell, and the 131 left print the same on both: 91 are `&.` calls, which do not reach this method (53 of them, with a boxed bound, do not build); 25 have a max that answers `coerce`; 15 have a max of a class with its own `<=>` and raise NoMethodError.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (run under 3.3.6 only)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical)
- [ ] Depends on: # (nothing)
