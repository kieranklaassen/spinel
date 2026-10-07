# Hand-over tools (not part of any piece)

The generators of the measured sets named in the hand-over of this branch's
pull request on the fork. No piece carries this directory: each piece is cut
from the commits its recipe lists.

- `gen.rb OUT` writes the family of `is_a?` through a constant (3,528 programs
  and their twins); `gen.rb OUT b5` the 300 more.
- `fam6-gen.rb FAM OUT`: the 96 witnesses of the guard on a method's read.
- `fam7-gen.rb OUT`: 936 programs with a class and a constant of one last name
  under different bodies.
- `fam8-gen.rb OUT`: 81 programs with const_set, private_constant, or the
  program's own is_a?.
- `fam9-gen.rb OUT`: 612 programs with a body CRuby looks up elsewhere first,
  BasicObject, remove_const, or the query named by a String.
- `fam10-gen.rb OUT`: 90 programs with a constant written by a required file,
  the require at the margin, inside a def, a block or an expression, or under
  a condition.
- `fam11-gen.rb OUT`: 368 programs (OUT/p) with a constant written by a bare
  name in a body that mixes in, opens or inherits one of CRuby's namespaces,
  and 234 (OUT/pv) with the value by a path through such a body.
- `fam12-gen.rb OUT`: 156 programs (OUT/lib) with a body under a library's,
  a builtin's or the program's own superclass or module, and 84 (OUT/sent)
  with const_set through send and the program's own is_a? under a definer,
  by a literal or a computed name.
- `fam13-gen.rb OUT`: 486 programs (OUT/p) with a constant given a class by
  a path whose body holds the class, inherits it or lacks it, under a
  const_missing of the program written six ways, a bare value beside a
  const_set of the class's name, and a write before the class's definition.
- `gd-gen.rb OUT`: 831 programs (OUT/p) asking a rescued exception for its
  class where two modules name a class alike (the fourth piece).
- `gd2-gen.rb OUT`: 2,580 one-row programs of the fourth piece with the
  name bound to something else (a constant at the program's level, in
  another module, an or-write, a second name, the module's own name held by
  a constant), asked bare, as a path and rooted from eleven places.
- `gd3-gen.rb OUT`: 648 one-row programs of the fourth piece with the name
  also held by an included module, a superclass or an enclosing module.
- `cmpcell.rb DIR A B` makes the two-rule table of two `include-order/quick.rb` runs cell
  by cell, for programs that print one row.
- `gd-attacks/`: the fourth piece's hand attacks (`r1` to `r6` the reader's
  programs, `c11` a module of the same name reached through an include).
- `early-gen.rb OUT`: the twelve early-call shapes.
- `num-gen.rb OUT`: the family of `instance_of?(Numeric)` on a boxed number.
- `bl-gen.rb OUT`: the family of `rescue` and `raise` through a constant
  (1,851 programs and their twins); `bl2-gen.rb OUT` its 69 attacks.
- `run.rb DIR TREE LABEL [JOBS]` builds and runs a directory under gcc and
  clang at collector stress unset, 1 and 2, against CRuby.
- `csum.sh TREE DIR OUT` sums the C a tree emits for a directory (tree path
  masked); `sum3.rb` makes the two-rule table from the runs and the sums,
  `tab2.rb` the table from two runs alone, and `cmp4.rb` counts by the sums
  what a later head of a piece gives up against an earlier one; `final.rb`
  makes the table of a head whose runs were made on an earlier head (a
  program keeps a run only where its C is the C that was run).
- `qc-gen.rb OUT` and `diamond-gen.rb LEVELS`: the fifth piece's programs,
  random graphs of include, prepend and superclass around a constant several
  bodies define, and the diamond of includes its table times; `csumt.sh`
  sums the C under a time limit and `utime.rb` prints a compile's user time.

- `include-order/`: the sixth piece's programs (method lookup through a
  module a class includes twice). `mro-gen.rb`, `mro2-gen.rb`, `mro3-gen.rb`
  and `mro4-gen.rb OUT [GRAPHS] [SEED]` write the four sets (1,080; 9,150
  with 40 graphs; 9,320 with 20; 4,480 with 45), one answer a program, the
  shape in the file's name; `csum4.sh TREE DIR OUT` sums the C, `quick.rb
  DIR TREE LABEL` runs each program once against CRuby's answer and
  `cmp2.rb DIR A B` makes the two-rule table; `own-check2.rb DIR SPINEL`
  compares the order of modules the compiler works out with CRuby's
  `ancestors` (SPINEL built with `order-dump.patch` on the piece);
  `cost-gen.rb OUT` writes the compile-time programs; `hand/` holds the
  attacks written by hand, among them the two that broke an earlier cut
  (`a1.rb`, a def under a condition; `d1.rb` and `d3.rb`, a class the order
  is not worked out for that copies from a module it was).

`texts/` holds the upstream texts of the three pieces as they are summed in
the hand-over: `numeric-*` for the first (a boxed number's
`instance_of?(Numeric)`), `pr-title.txt`, `pr-body-upstream-v14.md` and
`commit-message-v14.txt` for the second (the constant in `is_a?`; the `-v7`
to `-v13` files are its earlier texts), `bl1-*`
for the third (the constant in `rescue` and `raise`; its refactor's message
is in commit 69d79bf9), `gd-*` for the fourth (an exception's `is_a?` where
two modules name a class alike), `qc-*` for the fifth (the compile time of a
constant's lookup through a diamond of includes), `inc-*` for the sixth (a
module a class includes twice).

`patches/` holds each piece as a diff on the master it was last built on
(the file's name ends in that master's id): `git apply --index` on that
master gives the tree the hand-over names, and the piece's commit message
is the text beside it in `texts/`.

The second piece asks what leaves a whole program alone before it scans the
constant writes (`-v14`): `patches/piece2-ask-first-delta.patch` is that
change on the piece as it was (it applies above the piece on 4f8b737c1402
and on 759d120fd207), `piece3-ask-first-delta.patch` the same on the third
piece's head, and the `-on-759d120fd207` patches are the second piece above
the first, the third's refactor above the second, and the third above its
refactor. The emitted C is the same before and after (`tools/cident.sh`, and
the sums of `csum.sh` over the earlier sets); the two programs counted with
callgrind are 2,000 lines `K<i> = Integer`, `x = 5`, 4,000 lines
`p x.is_a?(K<i>)`, alone and with `class Bo < BasicObject; end` ahead.

The fourth piece asks the class table only where the path as written is
that class (`gd-pr-body-upstream-v3.md`, `gd-commit-message-v2.txt`; the
title is unchanged): `patches/piece4-exception-is-a-on-759d120fd207.patch`
is the piece on 759d120fd207, and `piece4-lexical-delta.patch` the change
on the piece as it was (it applies above the old patch on 759d120fd207 and
on this branch). On 759d120fd207 against CRuby 3.3.6: `gd-gen.rb`, 315 of
831 change, 254 lines wrong to right; `gd2-gen.rb`, 96 of 2,580 change, 96
cells wrong to right (the piece as it was: 903 change, 114 cells right to
wrong); `gd3-gen.rb`, 414 of 648 change, 414 cells wrong to right (as it
was: 534 change, 12 cells right to wrong); no line or cell right to wrong.
