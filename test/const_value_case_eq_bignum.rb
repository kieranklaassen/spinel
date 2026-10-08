# spinel: int64
# `K === x` for a constant that holds a value, with a Bignum on either side
# (const_value_case_eq.rb has the kinds that fit 32 bits).
LIMIT = 1..5
THREE = 3
BIG = 2**70
p(BIG === 2**70, BIG === 2**71, BIG === 3, BIG === "x", BIG === :a)
p(THREE === 2**70, LIMIT === 2**70)
mix = [2**70, 3, "x", nil]
p(mix.map { |v| BIG === v })
