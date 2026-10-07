### Piece 2, fifth form, on master 2801817b82e1

Class: fix. One commit on matz master 2801817b82e1 alone: dd13da998788d59282d6a8d4c67800e483fe599c, tree f68c34fcd995. Body: `handover-cp/boxed-attr-bitwise-pr-body-v5.md`. Title unchanged. Files: `src/codegen_stmt.c` (87 in, 39 out), `lib/spinel_rt.h` (8 in, one helper), `test/boxed_attr_bitwise_op_assign.rb` (121) with its `.expected` (123), and a second test, `test/boxed_attr_bitwise_reopened_operator.rb` (54) with its `.expected` (5). No nil helper; `emit_poly_call` untouched.

Picked onto master 5a752fceb48c (the tip at 12:15 UTC 10-07): c9744b1e185d7d0f0fd9e05fc18a9dc0f062a93b, tree 77985475b722. Built there; both tests pass with gcc and clang at SPINEL_GC_STRESS unset, 1 and 2; `ruby tools/gate.rb check` with the piece staged exits 0. The move from 2801817b to 5a752fce shares no function with the piece: in `src/codegen_stmt.c` it changes `emit_cond` and `str_mutate_append_bang_arms` and adds `strbuf_recv_hold` and helpers; `lib/spinel_rt.h` changes elsewhere than `sp_poly_bitop`. The families, the corpus and the cost were measured on 2801817b and are carried.

For the reader, who reads on 5390d300: commit b6dcb4675d0dd6b87ebc0b2a5df2cebcd2a90f7b is a child of 762da50f9bb8 (the first repair, which was read) holding the second repair alone: `git diff 762da50f9bb8 b6dcb4675d0d` is 26 lines in and 13 out of `src/codegen_stmt.c` plus the new test, the same source diff as the fourth form picked onto 2801817b against this commit. Built there; both tests pass with gcc and clang at the three stress levels. It is for the reading only.

#### The finding and the repair

Reader 4 (NOT READY, Finding 2): `subtree_is_pure_read` passes a scalar operator and a typed Array's index on their static types alone, and either is the program's own method once the program reopens the class. `o.v ^= (1.5 + 2)` with a reopened Float's `+` that writes `v`: Ruby and master 7, the fourth form 8 (rule (a)); `o.v ^= a[i]` with a reopened Array's `[]`: 1, the fourth form 14 (rule (a)); with nil in the slot, `o.v &= (1.5 < 2)` and a reopened Float's `<`: Ruby false, master NoMethodError, the fourth form true (rule (b)).

Ruled: the inverted test. The temp is skipped only where the operand can run none of the program's code. Master has no question "is this builtin's operator the program's own" that the three sites could ask (`user_defines_or_reads` also answers for readers and is switched off inside a builtin arm), so the question is asked by name over every class of the program: `subtree_call_may_run_program` (static, `src/codegen_stmt.c`, in the place of the fourth form's `subtree_call_arg_not_number`) answers yes for a call in the operand whose name a class of the program defines (`comp_method_in_class` over all classes; `!=` also where `==` is defined), or that has an argument that is no Integer or Float (the first repair). `emit_boxed_slot_read_first` reads the slot in place only where `subtree_is_pure_read` says yes and that says no. `subtree_is_pure_read` and `call_is_scalar_op` are untouched: every other caller's C is master's.

What it costs to ask by name: a program with a class of its own that defines `+` takes the temp at `o.v &= (i + 3)` though no code of the program runs there (the cost cells below).

#### The redefined-operator family (`handover-cp/gen-piece2-reopened.rb`, 600 programs)

Three op-assigns (`&=`, `|=`, `^=`) x four sites (the statement on a typed receiver, its value kept, in a method on `self`, through a boxed receiver) x who defines the operand's operator: a reopened Float, thirteen operators (`+ - * / % ** <=>` with 6 in the slot, the method writing 9; `< > <= >= == !=` with nil in the slot, the method writing true) x the receiver a literal, a local, an attribute (468); a reopened Array's `[]` on a typed Array (12); a reopened Integer's `+`, `<`, `==` x a literal and an attribute (72); a reopened TrueClass's `&` (12); and controls, a class of the program's own defining `+`, `<` and `[]` with the builtin as the operand (36). CRuby 3.3.6 as the answer; gcc; stress unset, 1 and 2. Each program rescues NoMethodError and TypeError and prints the class.

Master 2801817b, the fourth form picked unrepaired onto it, and this commit:

```
master right                  unrepaired wrong (a value)   repaired right    195   (rule (a) of the fourth form)
master NoMethodError (wrong)  unrepaired wrong (a value)   repaired right    162   (rule (b) of the fourth form)
master NoMethodError (wrong)  unrepaired right             repaired right     42
master right                  unrepaired right             repaired right    182
master NoMethodError (wrong)  unrepaired wrong (a value)   repaired wrong      3   (reached, not made; below)
master wrong (a value)        the same C on all three                         1
master no build               the same C on all three                        15
```

So over the 600: master 377 right, 208 wrong, 15 no build; this commit 581 right, 4 wrong, 15 no build. Rule (a): 0 (the fourth form: 195, all in the Float arithmetic and Array kinds). Rule (b): 0 made (the fourth form: 162); 3 reached, not made. The C of 438 programs differs from master's; 375 differ between the fourth form and this commit. No output differs between stress levels.

Under clang, stress unset, 1 and 2: the 438 rows are the gcc rows, and all 1,314 output files are byte for byte gcc's.

The 15 no-builds are master's own, by name ("unsupported call operator write") or in C, the same C here. The one wrong value on all three is the value site of the TrueClass kind (`y = (o.v |= (t & true))`), master's C.

#### The three lines reached, not made

`true__band__lit__or__obj`, `__boxed`, `__self`: a reopened TrueClass's `&` that writes the slot and answers false; nil in the slot; `o.v |= (t & true)`. Ruby prints false. Master raises NoMethodError (the nil slot's `|`). This commit prints true. The fault is master's with no op-assign in the program: a reopened TrueClass's `&` is never called (`x = (t & true); p x` prints true, and a counter in the method stays 0), so the operand is the builtin's true and nil | true is true.

- Half 1 (`handover-cp/piece2-twin-reopened.rb`): the twin changes ONLY the cured statement, `X.v |= (T & true)` into `X.v = X.v | (T & true)`, the form master compiles. Master builds the three twins and prints byte for byte what this commit prints for the programs: 3 of 3.
- Half 2 (`handover-cp/piece2-half2-reopened.rb`): master's C and this commit's C for the same program, temporaries renumbered and the frame's declaration set aside, through diff: in all three every changed line is the cured statement's own (master's `sp_poly_recv_i("|", ...)` store; here the slot read and the `sp_poly_bitop_int_first(` store), and the operand's code, `(lv_t & 1)`, stands in both: 3 of 3.

#### The earlier families on this master

The second repair moves none of them: the fourth form picked onto 2801817b and this commit emit the same C for every program of the order family (180), the family (924, 45 refused by both), the supplement (300), the brief's programs (197) and the coerce family (756).

And their rows stand as read on a39414338a22: for all 2,357 programs master's own C is the same on a39414338a22 and on 2801817b, and `diff master.c piece.c` is line for line the same on both masters (`handover-cp/bridge2.rb`: order 150 with a change and 30 with none; supplement 240 and 60; brief 15 and 182; coerce 540 and 216; family 747 and 132, 45 refused by master on both). They were not run again.

Of notes-piece2-v4.md, read so: "rule (a)/(b) breaks: 0" and "All 756 are right" are counts over the coerce family and say nothing of a shape outside it; the reader's three programs were outside it, and the family above is added for that shape.

#### Corpus

6,375 programs (`-c --no-line-map`): 6,371 identical, 4 differ; 3 by the build tree's path only; 1 changes (`test/poly_nil_op_assign.rb`, one line, as in the fourth form). No refusal changes. So asking by name moves no corpus program.

#### Cost (callgrind; instructions an op-assign against master 2801817b; an Integer in a boxed slot; 2,000,000 op-assigns; gcc / clang)

The twelve programs of `handover-cp/cost-piece2/`, measured again on this master, every cell as it was on a39414338a22:

- a literal operand (`and`, `or`, `xor`): -1 / -1 each
- a call with no argument (`andcall`, `orcall`, `xorcall`): +1, -1, -1 / 0, 0, 0
- a call with an argument, `b.v &= b.mask(i)` (`andarg`, `orarg`, `xorarg`): +1, +2, +1 / +1, +2, +1
- a comparison with a boxed argument, `b.v ^= (5 <=> b.w)` (`andcmp`, `orcmp`, `xorcmp`): 0, 0, 0 / -7, -7, -7

New, `handover-cp/cost-piece2-v5/` (master, the fourth form picked, this commit):

| operand | against master | against the fourth form |
|---|---|---|
| `(i + 3)`, no class defines `+` (`andsum`, `orsum`, `xorsum`) | -1 / -1 | 0 / 0 (same C) |
| `(i + 3)` beside a class with its own `+` (`andsumown`, ...) | 0 / +1 | +2 / +2 |
| `a[i & 3]`, no class defines `[]` (`andidx`, ...) | +1 / +2 | 0 / 0 (same C) |
| `a[i & 3]` beside a class with its own `[]` (`andidxown`, ...) | +2 / +4 | +2 / +2 |

The three operators give the same cell in every row. The index row is a cost the fourth form had and did not state: with an Array index as the operand the piece is one instruction (gcc), two (clang) dearer than master with no temp taken. The body's cost sentence now names the master and carries these cells.

#### The reader's sentences

1. The slot sentence (body and commit message): read in place only where the operand is a plain read and no call in it has a name a class of the program defines, or an argument that is no Integer or Float.
2. "Not covered": through a boxed receiver the three forms read the slot after the operand where the operand's own statements are set down ahead of the dispatch: a block, an Array literal holding a call, a `begin ... end`, a sequence in a rescue body. Probe: `r.v ^= [o.bump, 1].first`, `r.v ^= begin; o.bump; end`, `r.v ^= [1].map { |x| o.bump }.first` print 9 on master and here where Ruby prints 7; `r.v ^= o.bump` prints 7 on both; the typed `o.v ^= [o.bump, 1].first` printed 9 on master and prints 7 here.
3. The counts of notes-piece2-v4.md are counts over the coerce family (above).
4. The cost names its master, 2801817b, and was measured there.
5. The commit message said "with a plain operand costs no more than it did"; it now says a literal operand, which is what was measured, and the body carries the index cell.

#### Other checks, on 2801817b (gcc 13.3.0, clang 18.1.3)

- Tests: both of the piece's tests pass under gcc and clang at the three stress levels. On master the first has 95 of its 123 lines wrong; the second prints four right lines and dies at the fifth (NoMethodError for the nil slot). The fourth form prints the second wrong on all five lines (8, 14, 14, 15, true for 7, 1, 1, 7, false).
- The share-strings tests by hand (the Makefile's loop, 83 tests, plain and SPINEL_GC_STRESS=1): 0 failures.
- `ruby tools/gate.rb check` with the piece staged: exit 0 on the commit, the pick and the delta. `make gate` not run (no Ruby 4.0 here).
- Functions: the piece changes `emit_attr_global_const_write_stmt` and adds `program_defines_method`, `subtree_call_may_run_program`, `emit_boxed_slot_read_first` (`src/codegen_stmt.c`) and `sp_poly_bitop_int_first` (`lib/spinel_rt.h`).

#### Not here (as on master)

- `+=` to `>>=` on a boxed attribute read the slot after an operand that writes it.
- The three forms through a boxed receiver read the slot after an operand whose statements are set down ahead of the dispatch (sentence 2 above).
- An Integer attribute that holds nil answers the three forms from the sentinel. Held: upstream's nil plan names it.

#### Finds for the miner (master, none built here)

1. `subtree_is_pure_read` and `call_is_scalar_op` pass `1.5 + 2` and a typed Array's `a[i]` as free of effects in a program that reopens Float or Array, for every other caller on master (argument order, push, and the new receiver hold of a String append, which asks `subtree_is_pure_read`).
2. A reopened TrueClass's `&` is never called: `x = (t & true)` runs the builtin (silent).
