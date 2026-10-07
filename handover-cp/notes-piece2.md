### Piece 2: `&=`, `|=` and `^=` on a boxed attribute (its own commit; not in this branch's tree)

Class: fix (silent wrong answers). One commit on matz master 5390d3002886 alone: 15911319b19cd642776404e137865e88ffd4a682, tree 684c7b001bf97ce111f469207c23e0763e137f3a. The commit is in the fork the same way as piece 1's (a parent of this branch's head through the tree-keeping merge; this branch's tree does not hold it). `handover-cp/boxed-attr-bitwise.patch` is its `git format-patch -1 --no-signature`; `git am --committer-date-is-author-date` of it on 5390d300 gives the same commit. It touches `src/codegen_stmt.c`, `lib/spinel_rt.h` (one helper added beside `sp_poly_bitop`, nothing changed) and one new test; no nil helper. It needs nothing from piece 1: both add to `lib/spinel_rt.h` at different places, and both on 5390d300 apply in either order (tree 8e562e07147a).

Third form. Against the second form (5e78b518), by the second reading: the slot is read before the right operand runs. Where the operand is more than a plain read (`subtree_is_pure_read` says no), the slot's value is bound to a rooted temp before the operand's code (`emit_boxed_slot_read_first` in `src/codegen_stmt.c`, at the three sites: an object receiver, a native class's `:any` attribute, a boxed receiver's class switch). With a plain operand the C is the second form's, byte for byte. The reader's four programs are right under gcc and clang (`o.v ^= o.bump` 3; `o = Box.new(nil); o.v &= (o.v = 6; 3)` false; these two run again on 5390d300).

On 5390d300: the pick is clean and upstream's three new tests pass on it. Rows: the family of 924 and the order family under gcc, with 135 of the supplement, were measured on 8684d54c; the rest of the supplement, the brief's set and every clang row on 26d456ec; each carries to 5390d300, where this piece's C and master's are the same, program by program, as on the master the row was measured on (see piece 1 for the ground of a carried row, and for the newest master, d1081446). The cost and the test were measured on 5390d300. Upstream's new helpers answer a builtin's count and a handle's names; this piece asks neither.

Claims, with gcc 13.3 and clang 18.1 at `SPINEL_GC_STRESS` unset, 1 and 2, CRuby 3.3.6 as the answer:

- The order family, 180 programs (3 operators, 10 right operands of which 7 write the slot or run code, 6 sites; `handover-cp/gen-piece2-order.rb`):

```
NOBUILD            -> same               30
WRONG              -> WRONG              4     (as on master: | and ^ through a boxed receiver or a receiver of two classes, the operand carrying a block)
WRONG              -> same               36
same               -> same               110
differs between stress levels: 0
rule (a)/(b) breaks: 0
```

- The family of 924 programs (16 kinds of value in the slot, the three operators, 8 right operands, sites: `obj.v`, value position, `self.v`, a Struct member, a receiver of two classes, rescued, and a native class's `:any` attribute; `handover-cp/gen-piece2-family.rb`). The 792 without the native site:

```
NOBUILD            -> NOBUILD            111   (81: the receiver of two classes where the value's class has a typed slot; 30: a String-or-nil slot, refused by name; both as on master)
NOBUILD            -> WRONG              6     (right: see below)
NOBUILD            -> raise_same         117
NOBUILD            -> same               135
RAISE_WHERE_RIGHT  -> same               12
WRONG              -> WRONG              16    (6 right, see below; 10 the two-class receiver with a typed slot, as on master)
WRONG              -> raise_same         81
WRONG              -> same               95
raise_diff         -> raise_same         9
raise_same         -> raise_same         71
same               -> same               139
differs between stress levels: 0
```

  The 12 rows the table calls WRONG on the piece and are right: the rescued programs print the slot after the raise, a Hash (`{a: 1}` here, `{:a=>1}` in Ruby 3.3) or an object's address. So: 461 cured, 210 right before and after, 121 as on master, none lost.
- The native site (132 programs, a scratch native class with an `:any` attribute; nothing in the tree declares one): NOBUILD to right 66, WRONG to right 44, RAISE_WHERE_RIGHT to right 6, raise_diff to right 3, right before and after 13; all 132 right here.
- The supplement (`handover-cp/gen-piece2-supplement.rb`), 300 programs where the slot is boxed for certain and holds nil, false, true, 6 or "s": all 300 right here; master: 60 do not build, 27 raise where Ruby answers (nil in the slot), 141 wrong, 72 right.
- The brief's 197 programs: its 15 attribute programs are cured; the other 28 wrong ones are piece 1's; nothing right is lost; the same under clang.
- Rule (a): 0 right on master and not right here. Rule (b): 0 that raised, crashed or did not build on master and answer silently wrong here; 0 build failures became a crash.
- Cost (callgrind, 2,000,000 op-assigns on a boxed slot holding an Integer, instructions an op-assign against master, gcc / clang): with a plain operand `&=` -1 / -1, `|=` -1 / -1, `^=` -1 / -1; with a call as the operand `&=` +1 / -1, `|=` -1 / -1, `^=` -1 / -1.
- Corpus C against 5390d300 (6,357 programs): 1 changes, `test/poly_nil_op_assign.rb`, one line; its test and the new test pass at the three stress levels; optcarrot identical; 0 refusal changes. The share-strings tests, by hand: 82 of 82.
- The test passes under gcc and clang at the three stress levels; on master 94 of its 118 lines are wrong. `tools/gate.rb check` on the staged change: exit 0. `make gate` not run (no Ruby 4.0 here).
- Under clang every row of the three families and the supplement is the gcc row, program by program (1,404 of 1,404).

Not here (each as on master):

- `+=` to `>>=` on a boxed attribute read the slot after an operand that writes it (`o.v += o.bump` answers 17 for 11).
- `|=` and `^=` through a boxed receiver, or a receiver of two classes, read the slot after an operand that carries a block (4 programs of the order family: 13 for 7, 9 for 3).
- An Integer attribute that holds nil (the typed slot with the nil sentinel) answers `&=`, `|=` and `^=` from the sentinel (`|= 1` gives -9223372036854775807; Ruby true). Sized and held: upstream's own nil plan names it.
- `o.v &= 1` through a receiver of two classes does not build when one class's slot is typed and the other's boxed (81 programs of the family).
