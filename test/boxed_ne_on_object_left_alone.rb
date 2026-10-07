# spinel: int64
# A != written on Object is not a class's own: a boxed != keeps the arms it
# had for a Bignum and for nil.
class Object; def !=(other) = true; end
class Same; def ==(other) = true; end
row = [Same.new, nil, "paid", 2.0**70]
big = 2**70
p row[0] != big
p row[3] != big
p row[0] != nil
