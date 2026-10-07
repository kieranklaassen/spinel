### Piece 2 on master e527d205d274, after reader 4's PASS WITH TEXT FIXES (texts -v7; the patch is unchanged)

Class: fix; the cost is in the body's first lines. One commit on matz master e527d205d274 alone: 9f10a75ba2ac51438ffba949466f3ec38769ab7c, tree a4bb40289e31. It is the patch of 4f0906655329 (on d02a49fb7f74) and of dd13da998788 (on 2801817b82e1, where the earlier families were run) with a reworded message, `handover-cp/boxed-attr-bitwise-commit-message-v6.txt`. Body: `handover-cp/boxed-attr-bitwise-pr-body-v7.md`. Title unchanged.

The delta commit read by reader 4, b6dcb4675d0d, was cut for the reading only: its message names a stale base and is NOT the row's message. The row's message is the one above.

#### Built on e527d205d274 (gcc 13.3.0, clang 18.1.3)

- Both tests pass with gcc and clang at SPINEL_GC_STRESS unset, 1 and 2 (12 of 12 cells). On bare e527d205d274 the first has 95 of its 123 lines wrong; the second prints four right lines and dies at the fifth (NoMethodError for the nil slot).
- `ruby tools/gate.rb check` with the piece staged: exit 0. `make gate` not run (no Ruby 4.0 here).
- The earlier families, by the emitted change (`handover-cp/bridge2.rb`, master d02a49fb7f74 with the piece against master e527d205d274 with the piece): the redefined-operator family, 438 programs with the same change, 150 with none, 12 refused by both; the order family, 150 and 30; the supplement, 240 and 60. Master's own C moved in every program between the two masters; the piece's lines did not. Their rows stand as run.
- The move d02a49fb7f74..e527d205d274 changes `cond_operand_testable` and `emit_cond_andor` in `src/codegen_stmt.c` and `sp_poly_index_poly` in `lib/spinel_rt.h`: none is the piece's.
- Master 5c78f07e5906 (the tip at 14:40 UTC 10-07): the commit merges clean (`git merge-tree`, tree d6fff8c63243); the move changes nothing in `src/codegen_stmt.c` and only `sp_poly_str_aset_key` in `lib/spinel_rt.h`. Not built there.

#### The reader's four points

1. **The reached kind, as wide as it is.** Body and message now name it: where a program reopens TrueClass, FalseClass or NilClass, its own `&`, `|`, `^`, `!`, `==` and `!=` are not called on master (probe, 18 programs, `x = (t OP true)` with a counter in the method: the counter stays 0 in all 18; `handover-cp/gen-piece2-true-false-nil.rb` does not make these, they are six lines each). With nil in the slot master raised NoMethodError; the piece answers from the builtin's value.

   The family (`handover-cp/gen-piece2-true-false-nil.rb`, 540 programs: the three classes x the six operators x `&=`, `|=`, `^=` x five slot values (nil, 6, true, 2.5, "s") x the reopened method answering false or true; the method writes the slot; each program prints the slot or the class of the raise it rescues). CRuby 3.3.6; gcc; stress unset, 1 and 2 (no output differs between them). Master e527d205d274 and the commit:

   ```
   master raise (wrong)   the piece right            71
   master wrong value     the piece right           395
   master raise (wrong)   the piece wrong value      37   (reached, not made)
   master wrong value     the piece wrong value      37
   master right                                       0
   ```

   Master is right in none of the 540 (it reads the slot as an Integer). Rule (a): 0. Rule (b): 0 made, 37 reached: nil in the slot, `|=` 18, `^=` 18, `&=` 1 (NilClass's own `&` answering true). The 37 wrong on both: true in the slot (`&=` 18, `^=` 18, `|=` 1); master prints 1 or 0 (the slot read as an Integer), the piece true or false from the builtin's operand value: the reopened method is called on neither.
   - Half 1, the twin (`gen-piece2-true-false-nil.rb DIR twin`: only the cured statement changes, `o.v OP= E` into `o.v = o.v OP E`, the form master compiles): master prints for the twin, byte for byte, what the piece prints for the program: 37 of 37 (`handover-cp/piece2-tfn-table.rb`).
   - Half 2 (`handover-cp/piece2-tfn-half2.rb`): master's C and the piece's C for the same program, temporaries renumbered and the frame's declaration set aside, through diff: in all 37 every changed line is the cured statement's own, and the operand's C is the same text in both stores (`lv_t & 1`, `!lv_t`, `(lv_t), (1), 0` and so on): 37 of 37.
   - Under clang the piece's outputs for the first 270 are gcc's byte for byte.
   - The reader counted 43 such lines of 315 in a family of his own (21 class and operator pairs); this family has 18 pairs and finds the same three shapes.

2. **The cost, on one master, with its programs.** Callgrind, 2,000,000 op-assigns, an Integer in the slot, master e527d205d274 against the commit; instructions an op-assign, gcc / clang. The programs are `handover-cp/cost-piece2/`, `cost-piece2-v5/` and, new, `cost-piece2-v7/` (a constant index).

   | operand | `&=` | `\|=` | `^=` |
   |---|---|---|---|
   | `3` | -1 / -1 | -1 / -1 | -1 / -1 |
   | `(i + 3)` | -1 / -1 | -1 / -1 | -1 / -1 |
   | `a[i & 3]` | +1 / +2 | +1 / +2 | +1 / +2 |
   | `a[1]` | +2 / +2 | +2 / +2 | +1 / +2 |
   | `b.three` | +1 / 0 | -1 / 0 | -1 / 0 |
   | `b.mask(i)` | +1 / +1 | +2 / +2 | +1 / +1 |
   | `(5 <=> b.w)`, nil in `w` | 0 / -7 | 0 / -7 | 0 / -7 |
   | `(i + 3)` beside a class with its own `+` | 0 / +1 | 0 / +1 | 0 / +1 |
   | `a[i & 3]` beside a class with its own `[]` | +2 / +4 | +2 / +4 | +2 / +4 |
   | `a[1]` beside a class with its own `[]` | +3 / +4 | +3 / +4 | +4 / +4 |

   The 24 cells measured before are the same on 2801817b82e1, 5a752fceb48c, d02a49fb7f74 and e527d205d274. The reader's `a[k]` with k = 1, +2 / +2, is the `a[1]` row; his "k not a constant" (0 / +2), his `a[k]` beside a class with `[]` (+1 / +4) and his `<=>` (-8) are programs of his own, not these: the body now names each program it measured.

3. **"Not covered", the shapes as run on e527d205d274** (a boxed receiver `r`, `o.bump` writes the slot 9 and answers 2, 5 in the slot; Ruby 7): `r.v ^= [o.bump, 1].first`, `r.v ^= begin; o.bump; end`, `r.v ^= [1].map { |x| o.bump }.first`, `r.v ^= (begin; raise "x"; rescue StandardError; 1; o.bump; end)`, `r.v ^= (begin; o.bump; rescue StandardError; 1; end)` and `r.v ^= (o.bump if o)` print 11 on master and here; `r.v ^= o.bump`, `r.v ^= (o.bump rescue 3)`, `r.v ^= (1; o.bump)` and `r.v ^= (o ? o.bump : 1)` print 7 on both. `r.v += o.bump` and `o.v += o.bump` print 11 on both. The typed `o.v ^= [o.bump, 1].first` prints 11 on master and 7 here.

4. **The message.** "The slot is still read before the right operand runs" now carries "(but for the boxed-receiver case below)", as the body does, and a paragraph for the reached kind.

#### Carried from notes-piece2-v5.md and -v6.md, not run again

The five earlier families (2,357 programs), the redefined-operator family's rows (600), the corpus comparison (6,375 programs; one changes, `test/poly_nil_op_assign.rb`, one line) and optcarrot's C, by the emitted-change bridge above and the bridges of those notes.

#### Finds for the miner (master, none built here)

1. A reopened TrueClass, FalseClass or NilClass `&`, `|`, `^`, `!`, `==`, `!=` is never called (the counter stays 0 in 18 of 18); where the method answers a Symbol the call is typed by the method and prints a Symbol the program never made (`:mine`, or `:^`, `:!`, `:!=` for TrueClass's `^`, `!`, `!=`).
2. With such a NilClass `&`, `|` or `^` answering a Symbol, `o.v &= 1` on a boxed attribute holding nil does not build, and `o.v = o.v & 1` raises NoMethodError (the same here).
