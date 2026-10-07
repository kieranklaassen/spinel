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

`texts/` holds the upstream texts of the three pieces as they are summed in
the hand-over: `numeric-*` for the first (a boxed number's
`instance_of?(Numeric)`), `pr-title.txt`, `pr-body-upstream-v12.md` and
`commit-message-v12.txt` for the second (the constant in `is_a?`; the `-v7`
to `-v11` files are its earlier texts), `bl1-*`
for the third (the constant in `rescue` and `raise`; its refactor's message
is in commit 69d79bf9), `gd-*` for the fourth (an exception's `is_a?` where
two modules name a class alike), `qc-*` for the fifth (the compile time of a
constant's lookup through a diamond of includes).

`patches/` holds each piece as a diff on the master it was last built on
(the file's name ends in that master's id): `git apply --index` on that
master gives the tree the hand-over names, and the piece's commit message
is the text beside it in `texts/`.
