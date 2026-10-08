<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Under `SPINEL_GC_STRESS=2`, a Proc that may take anything lost a Range made in place when its body allocated:

```ruby
pat = [->(x) { [x].to_s.size > 3 }, 1][0]
n = 0
300.times { |i| n += 1 if pat.call(i..i + 2) }
p n          # 300 in Ruby; master at level 2: "the mark reached a freed slot"
```

A Range, a Time, a Rational, a Complex or a value-type object is a C struct. For a Proc with a boxed parameter it is boxed for the call alone and published to the side channel. The Proc's prologue reads the box into its parameter and clears the channel, and nothing roots a parameter: the caller holds its arguments, but here the caller held the struct, not its box.

The call site now holds the box. `proc_arg_box_hold` (`src/codegen_call.c`) declares a rooted holder where the argument's own temp is declared, and `emit_proc_arg_boxed` writes the box through it:

```c
sp_RbVal _t6 = sp_box_nil(); SP_GC_ROOT_RBVAL(_t6);
... (_sp_proc_poly_args[0] = (_t6 = sp_box_range(_t5)), <the call>)
```

It is used at the three places that publish an argument (a typed Proc's call, a boxed callable's call, the `call` arm of a dispatch on a class that defines `call`) and in `pat === value`. The holder starts as nil and is assigned where the box was made, so nothing is evaluated earlier. `Proc#[]` on a boxed receiver is a runtime call, `sp_poly_index_poly` (`lib/spinel_rt.h`): a new `sp_poly_call_aref_held` roots the argument and calls `sp_poly_call_aref`, and `sp_poly_index_poly` calls it in its place. The Symbol and String keys keep `sp_poly_call_aref`. A Class is passed the same way, but its box allocates nothing: it gets no holder.

One decision: rooting the parameter inside the Proc fixes every form in one line and cost 25 instructions on every call of a small Proc when it was built (on ab9b925aa). Held at the call site, a call with any other argument costs what it did. Callgrind on 3d629868d, 200,000 calls each, built with gcc: an Integer to a typed Proc 16,867,154 before and after, to a boxed Proc 23,067,600 before and after; a Range to a typed Proc 30,606,405 to 31,607,867 (5 a call), to a boxed Proc 4, `pat === (i..i + 2)` 2, `pat[i..i + 2]` 20 (62,818,949 to 66,818,949). Built with clang the same rows are 0, 0, 5, 4, 4 and 15.

The holder is laid where the callee or the pattern is boxed, whatever the box turns out to hold. A Range pattern in a boxed variable pays 5 a call for `pat === (i..i + 2)` (21,014,844 to 22,016,304), and a Rational handed to what is a Proc on one turn and an object with `call` on the next pays 9.5 (36,724,172 to 38,624,868).

`test/proc_boxed_struct_arg_root.rb` hands a Range, a Rational and a Complex made in place to a Proc 300 times through each form and counts the answers that are not Ruby's. On master (3d629868d, gcc and clang) it aborts at level 2 and at level 1 with `SPINEL_GC_VERIFY=1`, and is right in a plain run and at level 1. It is added to `GC_STRESS_TESTS`.

The generated C of 8 of the 6,254 programs under `test/` changes, each by the holder. `test/poly_callable_struct_args.rb` prints a wrong line at level 2 on master and passes; the other seven answer as before in every lane, gcc and clang (two of them, `range_float_end_bound_readers.rb` and `range_rational_membership.rb`, print a wrong line at level 2 on master and here).

To be merged after the pull request that keeps both ends of a String Range made on the spot. Without it a String Range with two ends made in place loses its first end before the call, and the holder then keeps a box whose first end is gone: a Method's Proc handed `("a" + i.to_s)..("c" + i.to_s)` is right on master at level 1 and prints a wrong line there with this change alone. With that pull request it is right at every level, with or without this one.

Not in this change:

- `case r when pat` with a boxed Proc pattern and a Range subject still aborts at level 2: `emit_when_boxed_test` hands the subject's box straight to `sp_penum_call1`.
- A boxed Proc's String answer as the left operand of `==` against a String made in place is compared after it was freed at level 2, built with gcc: `show.call(i) == "[#{i}, #{i}]"` counts 0 of 300, on master as here. With a Range argument master aborts before that comparison; with this change `show.call(i..i + 2) == "[#{i}..#{i + 2}, #{i}..#{i + 2}]"` counted 300 in the eight runs, and the comparison is as unheld as the other.
- A Float Range's `inspect` prints freed bytes for its first bound at level 2 (`p (3.0..3.5)`), on master as here.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag; it is `0`, four Ranges with their text, and `50`)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: the two compilers write the same C for it on 3d629868d)
- [ ] Depends on: #PR94 (both ends of a String Range made on the spot are kept; nothing in the code depends on it, the order does, as said above)
