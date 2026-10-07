### Piece 2, fifth form: the tip of 13:33 UTC 10-07, and body -v6 (an addendum to notes-piece2-v5.md)

No change to the commit's patch. Class: fix.

- Picked onto master d02a49fb7f74: 4f0906655329cd0958faac89780396ecb201cf26, tree ae6a6e9ec9cc687f41b6ac561d571ed2f1fd2ceb (clean; the same patch as dd13da998788 and c9744b1e185d). REBUILT there, because 5a752fceb48c..d02a49fb7f74 changes one line of `emit_attr_global_const_write_stmt`, a function the piece changes (the `**` row of its operator table now names `sp_poly_pow_recv`; upstream's boxed pow piece). Both tests pass with gcc and clang at SPINEL_GC_STRESS unset, 1 and 2 (12 of 12 cells); `ruby tools/gate.rb check` with the piece staged exits 0. On the bare tip (built) the first test has 95 of its 123 lines wrong and the second dies at its fifth line.
- What the piece emits is unchanged by the move: master's C is the same on 2801817b82e1 and on d02a49fb7f74, and `diff master.c piece.c` is line for line the same on both, for the 600 redefined-operator programs (438 with a change, 150 with none, 12 refused by master on both), the order family (150 and 30) and the supplement (240 and 60) (`bridge2.rb`, four trees built). The rows of notes-piece2-v5.md stand.
- Master 4f8b737c1402 (the tip at 13:39): d02a49fb7f74..4f8b737c1402 changes `cond_operand_testable` in `src/codegen_stmt.c` and `sp_poly_index_poly` in `lib/spinel_rt.h`, neither the piece's; `git merge-tree` of the pick into it is clean (tree b01847217694).

#### Cost, measured again (callgrind, 2,000,000 op-assigns, the 24 programs of `cost-piece2/` and `cost-piece2-v5/`)

On master 5a752fceb48c against the pick c9744b1e185d, and on master d02a49fb7f74 against the pick 4f0906655329, gcc and clang: all 48 cells of each pair are the cells of notes-piece2-v5.md, to the instruction an op-assign:

| operand | gcc | clang |
|---|---|---|
| a literal (`and`, `or`, `xor`) | -1 | -1 |
| a call with no argument (`andcall`, `orcall`, `xorcall`) | +1, -1, -1 | 0, 0, 0 |
| a call with an argument (`andarg`, `orarg`, `xorarg`) | +1, +2, +1 | +1, +2, +1 |
| a comparison with a boxed argument (`andcmp`, ...) | 0 | -7 |
| `(i + 3)`, no class defines `+` | -1 | -1 |
| `(i + 3)` beside a class with its own `+` | 0 | +1 |
| `a[i & 3]`, no class defines `[]` | +1 | +2 |
| `a[i & 3]` beside a class with its own `[]` | +2 | +4 |

#### Body -v6

The cost paragraph opens "What this changes" and names master d02a49fb7f74; no other sentence moved (`diff` of -v5 and -v6: the paragraph taken from the end and set first, its opening words).
