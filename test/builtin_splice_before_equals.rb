# A builtin written in Ruby that a program calls only with `==` right behind
# the name is spliced: there the name is a call, not a name ending in `=`.
counts = { 1 => 2, 2 => 1 }
p [1, 1, 2].tally==counts
p [2].tally==counts
