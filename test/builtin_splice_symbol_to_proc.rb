# A builtin written in Ruby that a program names only as `&:name` is spliced:
# the Symbol becomes a block that calls it.
p [[1, 1, 2], [3]].map(&:tally).map(&:to_a)
