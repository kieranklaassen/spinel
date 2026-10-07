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
- `early-gen.rb OUT`: the twelve early-call shapes.
- `num-gen.rb OUT`: the family of `instance_of?(Numeric)` on a boxed number.
- `bl-gen.rb OUT`: the family of `rescue` and `raise` through a constant
  (1,851 programs and their twins); `bl2-gen.rb OUT` its 69 attacks.
- `run.rb DIR TREE LABEL [JOBS]` builds and runs a directory under gcc and
  clang at collector stress unset, 1 and 2, against CRuby.
- `csum.sh TREE DIR OUT` sums the C a tree emits for a directory (tree path
  masked); `sum3.rb` makes the two-rule table from the runs and the sums.
