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

One decision: rooting the parameter inside the Proc fixes every form in one line and cost 25 instructions on every call of a small Proc when it was built (on ab9b925aa). Held at the call site, a call with any other argument costs what it did. Callgrind on ae2c38c71, 200,000 calls each: an Integer to a typed Proc 16,858,421 before and after, to a boxed Proc 12,262,148 before and after; a Range to a typed Proc 30,597,648 to 31,599,110 (5 a call), to a boxed Proc 4, `pat === (i..i + 2)` 2, `pat[i..i + 2]` 14 (64,018,438 to 66,818,438).

`test/proc_boxed_struct_arg_root.rb` hands a Range, a Rational and a Complex made in place to a Proc 300 times through each form and counts the answers that are not Ruby's. On master (ae2c38c71, gcc and clang) it aborts at level 2 and at level 1 with `SPINEL_GC_VERIFY=1`, and is right in a plain run and at level 1. It is added to `GC_STRESS_TESTS`.

The generated C of 11 of the 6,341 corpus programs changes, each by the holder. `test/poly_callable_struct_args.rb` failed at level 2 on master and passes; the other ten answer as before at every level.

To be merged after the pull request that keeps both ends of a String Range made on the spot. Without it a String Range with two ends made in place loses its first end before the call, and the holder then keeps a box whose first end is gone: a Method's Proc handed `("a" + i.to_s)..("c" + i.to_s)` is right on master at level 1 and prints a wrong line there with this change alone. With that pull request it is right at every level, with or without this one.

Not in this change:

- `case r when pat` with a boxed Proc pattern and a Range subject still aborts at level 2: `emit_when_boxed_test` hands the subject's box straight to `sp_penum_call1`.
- A boxed Proc's String answer as the left operand of `==` against a String made in place is compared after it was freed at level 2 (`show.call(i) == "[#{i}, #{i}]"`), with or without such an argument. With a Range argument master aborted there; with this change the program goes on to that comparison.
- A Float Range's `inspect` prints freed bytes for its first bound at level 2 (`p (3.0..3.5)`), on master as here.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag; it is `0`, four Ranges with their text, and `50`)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on ae2c38c71)
- [ ] Depends on: #PR94 (both ends of a String Range made on the spot are kept; nothing in the code depends on it, the order does, as said above)
