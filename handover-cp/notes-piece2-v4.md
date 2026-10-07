### Piece 2, fourth form, on master a39414338a22 (master's tip at 08:29 UTC, 10-07)

Class: fix. One commit on matz master a39414338a22 alone: c42407a4d0d749573a862dceeb09e5a01ddd7d92, tree b291df67cc59588f5dceb752a045f9a91b5a1c24. Body: `handover-cp/boxed-attr-bitwise-pr-body-v4.md`. Title unchanged. Files: `src/codegen_stmt.c`, `lib/spinel_rt.h` (one helper added), the test and its `.expected`. No nil helper; `emit_poly_call` untouched.

**What the repair moves, and what its temp costs.** Against the commit the second reader read, picked unrepaired onto this master (15911319b19c picked: 2df18e264e3a), the programs whose C goes from "slot read in place" to "slot bound to a rooted temp":

```
corpus (6,371 programs)            0   (its own test changes, by the new section)
order family (180)                 0
family (924)                       0
supplement (300)                   0
brief's programs (197)             0
coerce family (756, new)           312
```

The 312: an Integer or Float literal compared with a boxed argument at the statement site and in a method (`o.v &= (5 < o.w)`, `self.v &= (5 < @w)`), 240, and the same with an Integer past 62 bits as the argument, 72. The value site (`x = (o.v &= ...)`), `self.v &= (5 < w)` with `w` an attribute, a NaN argument (a Float: still read in place) and a receiver whose comparison is the program's own were not moved: they took the temp, or needed none, before the repair.

Cost of the temp where it is newly taken, `b.v ^= (5 <=> b.w)` with a boxed `w` holding 7, 2,000,000 op-assigns, instructions an op-assign: against the unrepaired commit +2 (gcc), +3 (clang); against master 0 (gcc), -7 (clang). No measured program is slower than master by the repair. The cells above master are the ones the unrepaired commit had too (a call with an argument, below).

#### The finding and the repair

Reader 4 (NOT READY, both rules): `subtree_is_pure_read` answers yes for a scalar comparison whose ARGUMENT is boxed (`call_is_scalar_op` asks the receiver and the result only), and the runtime's comparison then calls the program's `coerce`, which can write the slot. `o.v ^= (5 <=> o.w)` with a coerce that writes `v`: Ruby and master -7, the read commit -13 (rule (a)); with nil in the slot, `o.v &= (5 < o.w)`: Ruby false, master NoMethodError, the read commit true (rule (b)).

The repair asks a stricter question at the piece's three sites only: `emit_boxed_slot_read_first` reads the slot in place where `subtree_is_pure_read` says yes AND no call in the operand has an argument that is no Integer or Float (`subtree_call_arg_not_number`, new and static in `src/codegen_stmt.c`). `subtree_is_pure_read` and `call_is_scalar_op` are untouched, so every other caller's C is master's. The delta is 3 files, 67 lines in and 5 out: `src/codegen_stmt.c` (the new question, its use, and the two helpers set above the next function's own comment, where the read commit had left that comment above them) and a new section of the test (28 lines, 5 expected lines).

For the reader, who reads on 5390d300: commit 762da50f9bb86daa0a690fa052ad0d5752554848 is a child of 15911319b19c holding the repair alone (`git diff 15911319b19c 762da50f9bb8`, the same diff as 2df18e264e3a to c42407a4d0d7); built there, its test passes under gcc and clang at the three stress levels. It is for the reading only.

#### The coerce family (`handover-cp/gen-piece2-coerce.rb`, 756 programs)

Three operators; core block (432): the seven comparisons `<`, `>`, `<=`, `>=`, `==`, `!=`, `<=>`, an Integer or a Float literal as receiver, the boxed argument read as an attribute, an instance variable or a local, three sites (statement, value, in a method on `self`), nil in the slot with a coerce (or `==`) that writes true (every comparison), 6 in the slot with one that writes 12 (`<=>`); x block (108): the argument a NaN, `2**64 + 3`, and that Integer in a box; own block (216): the receiver an object whose `<=>`, `<` and `==` are the program's own and write the slot, typed and boxed. gcc, stress unset, 1 and 2, CRuby 3.3.6 as the answer.

Master a39414338a22 against the repaired commit:

```
right                                         -> right   300
NoMethodError where Ruby answers (nil slot)   -> right   288
a value where Ruby raises TypeError           -> right   168
differs between stress levels: 0
rule (a)/(b) breaks: 0
```

All 756 are right on the repaired commit. (The programs rescue and print the class, so the table tool calls master's 288 raises WRONG; they are split here by what was printed.)

The commit the reader read, picked unrepaired (2df18e264e3a), on the same family: 120 of 756 wrong, all in the core block at the sites the repair moves.

```
master right                 -> a wrong value   20    (rule (a): 6 in the slot, `<=>`; -13 for -7, 12 for 6)
master NoMethodError         -> a wrong value   100   (rule (b): nil in the slot; true for false, false for true)
master NoMethodError         -> right           188
master a value for TypeError -> right           168
master right                 -> right           280
```

Unrepaired against repaired: 120 wrong to right, 636 right and right, 0 the other way. Where the two commits emit the same C (444 programs) the unrepaired row is the repaired commit's row, carried; the 312 that move were run. The table tool's rule check sees the 20 and not the 100 (a rescued raise that prints its class reads as WRONG to it), so the rows of every old family that are WRONG on the piece were read again by what master printed: order family 4 and brief 28 print master's output; family 22, of which 10 print master's output and 12 are the right ones named in notes-piece2.md (a Hash's inspect, an object's address); supplement none.

Under clang, stress unset, 1 and 2: all 756 right, every row the gcc row.

#### The reader's four text points

1. The slot sentence (body and commit message) now says what the code does: read in place only where the operand is a plain read and no call in it has an argument that is no Integer or Float; the block case stays under "Not covered" and the sentence points at it.
2. Cost with a call as the operand: `b.v &= b.mask(i)` is +1 (`&=`), +2 (`|=`), +1 (`^=`) against master with both compilers, as the reader measured; the body says so. The twelve cost programs are in `handover-cp/cost-piece2/` (built with `spinel --cc=CC prog.rb -o bin`, counted with `valgrind --tool=callgrind`). All cells on a39414338a22, instructions an op-assign against master, gcc / clang: plain operand (`and`, `or`, `xor`) -1 / -1 each; a call with no argument (`andcall`, `orcall`, `xorcall`) +1, -1, -1 / 0, 0, 0; a call with an argument (`andarg`, `orarg`, `xorarg`) +1, +2, +1 / +1, +2, +1; a comparison with a boxed argument (`andcmp`, `orcmp`, `xorcmp`) 0, 0, 0 / -7, -7, -7.
3. "Rule (a): 0 ... Rule (b): 0" in notes-piece2.md was a count over the families of that hand-over, not over programs; the reader's two programs were outside them. Read it so. The count over the families stands, and the coerce family above is added for the shape that was outside.
4. "Not here" 4 of notes-piece2.md gave a false reason. `[C.new(6), D.new(6)].each { |o| o.v &= 3 }` with C's slot typed and D's boxed builds and is right, on master and here. The 81 programs of the family that do not build have a slot value or an operand that is no Integer: the typed class's arm keeps its own code, which master refuses by name ("the operand of an `op=` given a Array, which no conversion keeps in its sp_int slot") or which does not compile. As on master.

#### On master a39414338a22 (gcc 13.3.0, clang 18.1.3, stress unset, 1, 2)

- Tests: `test/boxed_attr_bitwise_op_assign.rb`, `test/poly_nil_op_assign.rb` (the one corpus program whose C changes) and upstream's six boxed-value tests pass under gcc and clang at the three stress levels (16 of 16 lines, 48 runs). On master the piece's test has 95 of its 123 lines wrong.
- Corpus C (`-c --no-line-map`, 6,370 programs): 6,366 identical, 4 differ; 3 by the build tree's path only; 1 changes (`test/poly_nil_op_assign.rb`, one line). optcarrot identical, 0 refusal changes.
- The old families' C: for the order family's 180, the family's 924 (45 refused by `-c` on master and here, on both masters), the supplement's 300 and the brief's 197, `diff master.c piece.c` on a39414338a22 is line for line the diff of 15911319b19c on 5390d300 (1,152 with a change, 404 with none); no refusal moved. Their rows stand as read; they were not run again.
- The reader's two programs and their kin (statement site, instance variable in a method, local): right, where the unrepaired pick is wrong.
- The share-strings tests by hand (`--share-strings`, stress unset and 1): 82 of 82. `tools/gate.rb check`: exit 0. The C tests: 2 of 2. These lines were measured on the tree before the two helpers were set above the comment (891a92ee831f); the final commit emits the same C for the corpus (6,371), the coerce family (756) and the four old families (1,601), bar the four corpus programs that print the revision, and its two tests and the gate check were run again on it.
- Functions: the piece changes `emit_attr_global_const_write_stmt` and adds `subtree_call_arg_not_number`, `emit_boxed_slot_read_first` (`src/codegen_stmt.c`) and `sp_poly_bitop_int_first` (`lib/spinel_rt.h`). It shares no function with master's moves since 5390d300 (in `src/codegen_stmt.c` those are `tail_iter_receiver` and `emit_stmt_tail_inner`), nor with the boxed `to_i` change, the conversions' rewording or the send by a Symbol.
- Not run: `make gate` (no Ruby 4.0 here).

#### Master's tip at 08:47 UTC, b4d30a1d3f9c (thirteen commits on)

Both pieces merge clean and share no function with the move (`sp_poly_to_i_meth` for a boxed IO, a String Range's `step`, the display arm's plan-check record, `each_with_index_chain` and `emit_stmt_tail_inner`, `analyze.c`, `call_plan.c`, `spinel_parse.c`). Picked and built there: piece 1 65ff0d884f59 (tree 87f1d37ffd72), piece 2 011fd40d0e05 (tree 11aeff090de1). Each piece's tests, upstream's seven boxed-value tests (with the new `boxed_io_to_i`) and, for piece 2, `poly_nil_op_assign` pass under gcc and clang at the three stress levels: piece 1 22 of 22 lines, piece 2 18 of 18. Nothing else was run there. At 09:19 UTC master is f3da0151f9dc, one commit on (`sp_bt_format` in `lib/sp_cold.c`, a backtrace frame's line): both merge clean, no function shared, nothing run.

#### Not here (as on master; the list of notes-piece2.md but its fourth line)

- `+=` to `>>=` on a boxed attribute read the slot after an operand that writes it.
- `|=` and `^=` through a boxed receiver, or a receiver of two classes, read the slot after an operand that carries a block.
- An Integer attribute that holds nil answers the three forms from the sentinel. Held: upstream's nil plan names it.
- `call_is_scalar_op` passes `5 <=> boxed` as free of effects for its other callers (argument order, push); sent on for the miner, not touched here.
