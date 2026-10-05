<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

Under `SPINEL_GC_STRESS=2`, a Proc that may take anything lost a Range made in place when its body allocated:

```ruby
pat = [->(x) { [x].to_s.size > 3 }, 1][0]
pat.call(i..i + 2)          # master at level 2: "the mark reached a freed slot"
```

It does not always stop: of 39 ways to hand such a Proc an Integer Range, master at level 2 prints wrong lines and exits 0 in 23.

A Range, a Time, a Rational, a Complex or a value-type object is a C struct. For a Proc with a boxed parameter it is boxed for the call alone and published to the side channel. The Proc's prologue reads the box into its parameter and clears the channel, and nothing roots a parameter: the caller holds its arguments, but here the caller held only the struct, not its box.

The call site now holds the box. `proc_arg_box_hold` (`src/codegen_call.c`) declares a rooted holder where the argument's own temp is declared, and `emit_proc_arg_boxed` writes the box through it:

```c
sp_RbVal _t6 = sp_box_nil(); SP_GC_ROOT_RBVAL(_t6);
... (_sp_proc_poly_args[0] = (_t6 = sp_box_range(_t5)), <the call>)
```

It is used at the three places that publish an argument (a typed Proc's call, a boxed callable's call, the `call` arm of a dispatch on a class that defines `call`) and in `pat === value`. `Proc#[]` on a boxed receiver is a runtime call, `sp_poly_index_poly` (`lib/spinel_rt.h`), so there the header holds the box: a new `sp_poly_call_aref_held` roots the argument and calls `sp_poly_call_aref`, and `sp_poly_index_poly` calls it in place of `sp_poly_call_aref`. That is the whole header change: one function added and one call retargeted; no signature, macro or struct changes and nothing is removed. `sp_poly_call_aref` itself keeps its two other callers (a Symbol key, a String key) and its cost. Nothing is evaluated earlier than before: the holder starts as nil and is assigned where the box was made. An argument of any other kind compiles as it did, and so does a Class: it is passed the same way, but its box allocates nothing, so it gets no holder.

Rooting the parameter inside the Proc was built first: it fixes every form in one line and costs 25 instructions on every call of a small Proc. Held at the call site it costs nothing there. Measured on ab9b925aa (callgrind, 200,000 calls each): `f.call(i)` 16,456,948 before and after, and the same count before and after for an Integer handed to a boxed Proc, a Class argument and `f[:a]`; `f.call(i..i + 2)` on a typed Proc 29,995,775 to 30,997,237, 5 instructions a call; on a boxed Proc 4; `pat === (i..i + 2)` 3; `f[i..i + 2]` on a boxed Proc 13 (63,410,150 to 66,010,150). `pat === value` with such an operand pays for the holder when `pat` turns out not to be a Proc too, 5 instructions, and a dispatch whose other arm is an object's `call` 9.5.

`test/proc_boxed_struct_arg_root.rb` hands a Range, a Rational and a Complex made in place to a Proc 300 times through each form (`call`, `.()`, `yield`, `[]`, `===`, two arguments, a typed Proc, a dispatch between a Proc and an object with `call`) and counts the answers that are not Ruby's. On master (ab9b925aa, Linux x86-64, gcc and clang) it aborts at level 2 and at level 1 with `SPINEL_GC_VERIFY=1`; a plain run and level 1 are right (20,000 rounds tried). Each answer is assigned to a local before it is compared: a boxed Proc's String answer as the left operand of `==` is another fault, the third line under "Not in this change". With this change it prints Ruby's output at every level with both C compilers. It is added to `GC_STRESS_TESTS`, the only leg that fails without the fix.

Measured with both compilers built on ab9b925aa (the branch merged with it):

- 106 programs (other routes to a Proc, other values, reductions of what failed), run plain and at levels 1 and 2: the plain run answers the same before and after in all of them. 32 are right on master under all three and stay right. Of the other 74, 35 are right under all three with this change and 5 more under some; the rest fail as on master, each for a cause listed below, and five of them now run past the lost box to one of the last two faults there, where master aborted. One String Range program right on master at level 1 is not with this change alone; that is the next paragraph.
- Generated C: 8 of the 5,797 programs in `test/*.rb` and 3 of the 156 package tests (the logger's, a Time handed to the formatter) change, each by the holder; the 64 programs in `benchmark/` and optcarrot are byte-identical. All 11 print the same bytes before and after in a plain run and at level 1; at level 2 three fail on master and two with this change (`poly_callable_struct_args` now passes; `range_float_end_bound_readers` and `range_rational_membership` print the same wrong bytes before and after, with exit 0).

To be sent after #PR94 (both ends of a String Range made on the spot are kept). Without it, a String Range with both ends made in place loses its first end before the call, and the holder then keeps a box whose first end is already gone: of 39 ways to hand a Proc `("a" + i.to_s)..("c" + i.to_s)`, master is right in 15 at level 1 and in none at level 2, this change alone in 27 and none (one of the 15, a Method's Proc, among those it gets wrong), #PR94 alone in 39 and 16, and the two together in 39 of 39 at every level, with gcc and with clang.

Not in this change:

- `case r when pat` with a boxed Proc pattern and a Range subject still aborts at level 2: `emit_when_boxed_test` hands the subject's box straight to `sp_penum_call1`.
- Three routes that hand over two boxes or go through another call still lose the box at level 2, on master and with this change, and are right in a plain run on both: a boxed Proc's `[]` with two arguments (`pat[a, b]`), `curry` (`pat.curry[a][b]`), and an object's `call` with two such arguments reached through the dispatch this change touches. `Fiber#resume` with a Range is the same fault outside a Proc call. The first and the third make both boxes in argument position, so they need the call site's holders, not a runtime wrapper.
- A boxed Proc's String answer as the left operand of `==` against a String made in place is compared after it was freed at level 2 (`show.call(i) == "[#{i}, #{i}]"`), with or without such an argument. With a Range argument master aborted there; with this change the program goes on to that wrong comparison.
- A Float Range's and a String Range's `inspect` and `to_s` print freed bytes for the first bound at level 2 (`p (3.0..3.5)`), on master as here: both bounds' text is built with nothing holding the first. A Proc that prints such a Range it was handed aborted on master at level 2; with this change it goes on to print those bytes.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag; it is `0`, four Ranges with their text, and `50`)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on ab9b925aa)
- [ ] Depends on: #PR94 (both ends of a String Range made on the spot are kept; nothing in the code depends on it, the order does, as said above)
