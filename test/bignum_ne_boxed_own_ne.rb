# spinel: int64
# A class of the program with a != of its own: the boxed receiver of
# `box != bignum` may be such an object, and the Bignum pair would answer
# for it by negating its ==. That comparison keeps the read it had; the
# other three ask the object's ==.
class Odd
  def ==(other) = true
  def !=(other) = true
end
row = [Odd.new, 1]
big = 2**70
p row[0] != big
p big != row[0]
p row[0] == big
p big == row[0]
