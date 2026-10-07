# spinel: int64
# A != written on Numeric is not a class's own: a boxed Float against a
# Bignum keeps the arm it had.
class Numeric; def !=(other) = true; end
class Same; def ==(other) = true; end
row = [Same.new, nil, "paid", 2.0**70]
big = 2**70
p row[3] != big
