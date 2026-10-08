# spinel: int64
# `K === x` for a constant that holds a value, with a Bignum on either side
# (const_value_case_eq.rb has the kinds that fit 32 bits).
LIMIT = 1..5
THREE = 3
BIG = 2**70
big = 2**70
bigger = 2**71
p(BIG === big, BIG === bigger, BIG === 3, BIG === "x", BIG === :a)
p(THREE === big, LIMIT === big)
mix = [2**70, 3, "x", nil]
p(mix.map { |v| BIG === v })
