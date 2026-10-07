# Master's move from 8dc5522541bb to 42557a3c0e7c: this thread's four pieces

Read at 22:20 UTC 10-07 (`git ls-remote`), about 70 commits. Each piece's test was run on the bare tip first; then the merge by exit status, the functions the move shares with the piece (`fnover.rb`), one build, the cells, the staged gate check, `--share-strings`, the bridge (`bridge2.rb`: is the piece's C, read as a diff against master's C, the same lines on both tips?), the corpus, optcarrot's C and the cost cells.

The tip cures none of the four and breaks none. One conflicts.

## An Integer Array searched for a boxed Float or Rational (a76c414187930b9d4db56b869e2c5de48679c19b on 8dc5522541bb)

Stays good: the merge is clean (tree 813069ff803b) and the move touches no function of the piece.

- Bare tip: `test/int_array_boxed_number_needle.rb` prints 11 of its 33 lines wrong and misses one, as on 8dc5522541bb.
- One build on the tip: 6 of 6 cells; staged `ruby tools/gate.rb check` rc 0; `--share-strings` right.
- Bridge: the family 2,616 of 2,616 the same lines (1,215 with a change); 13 attacks 13 of 13. Master's C for all of them is the same on both tips.
- Corpus (6,469 programs): 11 differ, 3 by the path in a comment and the same 8 tests as before; no refusal changes. Optcarrot's C identical.
- Cost (callgrind, 300,000 calls): gcc `include?` with an Integer needle 0, `index` and `rindex` -5, a String or Symbol needle +5; clang 0, -3, +6 to +8. The figures of the hand-over.

## A boxed String or Array times a Float (1f94cd612d0d on 8dc5522541bb)

CONFLICTS, in src/codegen.c: the piece and the move each add a line at the same spot of `emit_regex_section`, after the user operator hook (the move's is the `sp_user_eql_hook` line). Resolved by hand: both kept, the piece's five lines after the move's.

- The re-cut commit: a1ab4dcad78ba556e10b50a201b9da2a68de4697 on 42557a3c0e7c, tree 05c6f7044805; the message is 1f94cd612d0d's byte for byte; the added and removed lines are the same 207 as on 8dc5522541bb, in the same order (cmp). The only other shared name is a neighbouring declaration in src/compiler.h.
- Bare tip: `test/poly_times_float_count.rb` prints 32 of its 36 lines wrong; `test/poly_times_float_count_big.rb` its one line; `test/poly_times_own_star.rb` is right there, as it is meant to be (it pins the stand-down).
- On the tip: 18 of 18 cells; staged gate check rc 0; `--share-strings` right for the three.
- Bridge: the family's 3,100 programs that compile emit master's C under the piece on both tips (the change is in the runtime; the other 32 are refused by both trees on both tips); of 41 attacks 37 the same lines (23 with a change), 4 refused by both.
- Cost (callgrind): 0.00 a call on the six cells with gcc and with clang (18 to 126 instructions over a whole run; -2,934 and -2,372 on the Array-times-String cell).
- Corpus: 18 differ, 3 by the path and the same 15 that gain the init line; no refusal changes. Optcarrot's C identical.
- The family is being run again on the tip (the runtime moved); its outputs are compared with the ones of the hand-over.

## The freeze pair

notes-freeze-stack.md, section "The move to 42557a3c0e7c". Commit 1 shares no function with the move; commit 2 shares `emit_poly_call0_arms` and is rebuilt and bridged there.
