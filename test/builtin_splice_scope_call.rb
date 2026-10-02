# A builtin written in Ruby that a program calls only as `recv::name` is
# spliced, as it is for `recv.name`.
p [1, 1, 2]::tally.to_a
p [1, 2, 3]::partition { |v| v > 1 }
