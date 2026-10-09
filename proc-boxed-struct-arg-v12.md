<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Under `SPINEL_GC_STRESS=2`, a Proc that may take anything lost a Range made in place when its body allocated:

```ruby
pat = [->(x) { [x].to_s.size > 3 }, 1][0]
n = 0
300.times { |i| n += 1 if pat.call(i..i + 2) }
p n          # 300 in Ruby; master at level 2: "the mark reached a freed slot"
```

A Range, a Time, a Rational, a Complex or a value-type object is a C struct. For a Proc with a boxed parameter it is boxed for the call alone and published to the side channel. The Proc's prologue reads the box into its parameter and clears the channel, and nothing roots a Proc's parameter: the caller holds its arguments, but here the caller held the struct, not its box.

The call site now holds the box. `proc_arg_box_hold` (`src/codegen_call.c`) declares a rooted holder and `emit_proc_arg_boxed` writes the box through it:

```c
sp_RbVal _t6 = sp_box_nil(); SP_GC_ROOT_RBVAL(_t6);
... (_sp_proc_poly_args[0] = (_t6 = sp_box_range(_t5)), <the call>)
```

It is used at the three places that publish an argument: a typed Proc's call, a boxed callable's call, and the `call` arm of a dispatch on a class that defines `call`, where the holder sits inside the callable's block. The holder starts as nil and is assigned where the box was made, so nothing is evaluated earlier. In `pat === value` the holder is declared in the Proc's arm alone, so a pattern that is a Range, a Class, a Regexp or a Method takes the arm it took, with the C it had. `Proc#[]` on a boxed receiver is a runtime call, `sp_poly_index_poly` (`lib/spinel_rt.h`): a new `sp_poly_call_aref_held` roots the argument and calls `sp_poly_call_aref`, and `sp_poly_index_poly` calls it for a Proc. The test for a Proc sits inside the arm a callable already takes (`sp_poly_is_call_aref`), so indexing a boxed Hash, Array or String there runs the instructions it ran. The Symbol and String keys keep `sp_poly_call_aref`. A Class is passed the same way, but its box allocates nothing: it gets no holder.

A Method is not held for: its parameter is rooted by the method. `m.call(i..i + 2)`, `m[i..i + 2]` and `m === (i..i + 2)` on a boxed Method whose body allocates answer right on master in every lane, gcc and clang.

One decision: rooting the parameter inside the Proc fixes every form in one line and cost 25 instructions on every call of a small Proc when it was built (on ab9b925aa). Held at the call site, a call with any other argument costs what it did, and so does an index on a boxed value that is no callable. Callgrind on 0e8befeb3, 200,000 calls each; the number in brackets is instructions a call. The four rows inside a method or with a body that allocates were counted on ed9861279:

| call | gcc | clang |
|---|---|---|
| an Integer to a typed Proc | 16,867,151, the same | 13,622,821, the same |
| an Integer to a boxed Proc | 23,067,598, the same | 22,823,527, the same |
| a Range to a typed Proc | 30,606,402 to 31,607,864 (5) | 27,412,044 to 28,413,508 (5) |
| a Range to a typed Proc whose body makes a String | 167,234,667 to 168,814,468 (8) | 161,650,994 to 163,230,136 (8) |
| a Range to a boxed Proc | 42,029,462 to 42,830,558 (4) | 37,834,302 to 38,435,397 (3) |
| `pat === (i..i + 2)`, a Proc | 43,823,424 to 44,824,884 (5) | 39,428,947 to 40,230,413 (4) |
| `pat[i..i + 2]`, a Proc | 63,218,946 to 66,018,946 (14) | 54,225,535 to 57,825,535 (18) |
| `pat === (i..i + 2)`, a Range or a Method | 0 | 0 |
| `pat === (i..i + 2)` inside a method, a Range | 26,222,910 to 26,624,370 (2) | 27,427,622 to 27,629,081 (1) |
| the same, a Proc | 48,431,404 to 49,832,864 (7) | 44,236,918 to 45,438,378 (6) |
| `m.call(i..i + 2)`, a boxed Method | 76,629,091 to 77,230,189 (3) | 66,233,546 to 67,034,642 (4) |
| the same inside a method | 80,637,128 to 81,838,222 (6) | 70,441,592 to 72,042,687 (8) |
| `m[i..i + 2]`, a boxed Method | 98,624,844 to 99,024,844 (2) | 83,629,588 to 83,229,588 (2 fewer) |
| `h[k]` on a boxed Hash | 57,670,353, the same | 52,626,107, the same |
| `a[i]` on a boxed Array | 26,868,313, the same | 21,424,087, the same |
| `s[i]` on a boxed String | 72,469,932, the same | 75,825,740, the same |

Three of these are paid by a call that needed no holder, and master ran each of them right. A boxed Method called with `.call` shares its site with a boxed Proc, and the holder is declared before the kind is known (3 and 4 at the top level; 6 and 8 inside a method, where the holder is a slot of the method's frame). A Method through `[]` pays the test that tells it from a Proc, inside the arm the two share (2 with gcc; the clang build runs 2 fewer). And the holder of `pat === value` is a slot of the enclosing function's frame: the test itself costs a pattern that is no Proc nothing, but a method that holds such a test pays for the slot each time it is entered, 2 with gcc and 1 with clang, whatever the pattern (a Proc there pays 7 and 6). A Rational handed to what is a Proc on one turn and an object with `call` on the next pays 19 on the Proc's turn with gcc, 17 with clang, and nothing on the object's (36,724,169 to 38,624,865 over both with gcc). The 5 of a Range handed to a typed Proc is what the call site pays; the held box is also one more root for a collection to mark, and a Proc whose body allocates pays 8.

`test/proc_boxed_struct_arg_root.rb` hands a Range, a Rational and a Complex made in place to a Proc 300 times through each form and counts the answers that are not Ruby's. On master (0e8befeb3, gcc and clang) it aborts at level 2 and at level 1 with `SPINEL_GC_VERIFY=1`, and is right in a plain run and at level 1. It is registered for the stress lanes by its header line (`# spinel: gc-stress`).

The generated C of 12 of the 6,565 programs under `test/`, `benchmark/` and `packages/*/test/` changes, each by the holder: eight under `test/`, three tests of the logger package and one of the ffi package. `test/poly_callable_struct_args.rb` prints a wrong line at level 2 on master and passes. The other seven under `test/` answer as before in the seven lanes, gcc and clang (two of them, `range_float_end_bound_readers.rb` and `range_rational_membership.rb`, print a wrong line at level 2 on master and here), and the four package tests pass as before in a plain run and at level 1, built with gcc.

This relies on "The two ends of a String Range made on the spot are both kept, and made in order", which is in master. Without it a String Range with two ends made in place loses its first end before the call, and the holder then keeps a box whose first end is gone: on a master without it (0e8befeb3) a Method's Proc handed `("a" + i.to_s)..("c" + i.to_s)` was right at level 1, gcc and clang, and printed a wrong line there with this change alone. The counts over the whole set of such programs were taken on earlier masters and were not run again on this one: of 39 on 9c7ea3ce0, master was right in 15 at level 1 and this change alone in 27 (it gained 13 and lost that one), and none was right at level 2 on either; with that change beneath, on ab9b925aa, all 39 were right at every level, with or without this one.

Not in this change:

- `case r when pat` with a boxed Proc pattern and a Range subject still aborts at level 2: `emit_when_boxed_test` hands the subject's box straight to `sp_penum_call1`.
- A boxed Proc's String answer as the left operand of `==` against a String made in place is compared after it was freed at level 2, built with gcc: `show.call(i) == "[#{i}, #{i}]"` counts 0 of 300, on master as here. With a Range argument master aborts before that comparison; with this change `show.call(i..i + 2) == "[#{i}..#{i + 2}, #{i}..#{i + 2}]"` counted 300 in the eight runs, and the comparison is as unheld as the other.
- A Float Range's `inspect` prints freed bytes for its first bound at level 2 (`p (3.0..3.5)`), on master as here.
- A Method's Proc (`K.new.method(:f).to_proc`) called through `[]` or `===` is not handed its argument, in a plain run, on master as here: with `def f(r) = r.to_s`, `pat[7..9]` answers `"0"` for `"7..9"`. Where such a Proc takes turns with a lambda at one site, the lambda's turns were wrong at level 2 on master and are right here, so the line printed at level 2 is now the one master prints in a plain run, the Method's turns as wrong as there.
- The order of effects, which is master's: `pat.call(a..a + 2, (a += 1; a..a + 2))` prints `[1..3, 1..3]` for `[0..2, 1..3]` in a plain run on master, which aborts on it at level 2; here level 2 prints that same line.
- An argument that rebinds the receiver: `pat.call((pat = (i.odd? ? f : g); i..i + 2))`, where `pat` takes turns between two lambdas, answers `"g[0]"` for `"g[1..3]"` on the turns that rebind, in a plain run on master, which aborts on it at level 2; here level 2 prints that same line.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here, built from nothing, on two masters. On 0e8befeb3, the base this change was read on: the test in the seven collector lanes with gcc and clang, with and without `--share-strings` (master aborts at `SPINEL_GC_STRESS=2` and at level 1 with the verifier; this change is right in every one); `ruby tools/gate.rb check`; the generated C of the 6,565 programs, changed in the twelve named above; optcarrot, checksum 59662; `make share-strings-test` and `make int-min-test`, both pass. On 5518e5934, where this commit is the same change replayed (the same patch, its test registered by its header line where it had a line in the Makefile's list; master has since changed another line of `emit_call_poly_callable_arms`): all of it again, with the same answers from master and from this change; the generated C of the 6,629 programs there, changed in the same twelve, the eight under `test/` answering in the seven lanes as on the older base; optcarrot's C byte-identical; `make share-strings-test` and `make int-min-test`, both pass.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: none

The `.expected` file was written from ruby 3.3.6 with `--enable-frozen-string-literal`; it is `0`, four Ranges with their text, and `50`. CRuby 4.0 is not on the machine that ran the checks above, so the first box is left for the gate's run. No value is past 2^31. optcarrot's generated C did not change. It depends on no other pull request: "The two ends of a String Range made on the spot are both kept, and made in order", which it relies on as said above, is in master.
