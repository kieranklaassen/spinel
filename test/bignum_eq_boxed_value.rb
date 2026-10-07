# spinel: int64
# A Bignum the compiler has typed, == or != a value known only at run time:
# the value is asked what it holds. Read as a Bignum it was 0 unless it was a
# number, so a zero Bignum was == nil, and a Float lost its fraction.
total = 2**64
total -= 2**64
row = [nil, "paid", 3.7, :due, [0], false]
p total == row[0]
p total == row[1]
puts "nothing owed" if total == row[0]
p total != row[0]
p row.count { |v| total == v }
p row[0] == total
p row.map { |v| v != total }

three = total + 3
p three == row[2]
p three != row[2]

big = 2**70
nums = [3, 3.0, 2**70, 1180591620717411303424.0, 0, 0.0, Rational(3, 1)]
p nums.map { |v| three == v }
p nums.map { |v| big == v }
p nums.map { |v| total == v }
p nums.map { |v| v != big }
p nums.map { |v| v == three }

class Money
  attr_reader :cents
  def initialize(cents) = @cents = cents
  def ==(other) = other.is_a?(Money) ? cents == other.cents : cents == other
end
owed = [Money.new(0), Money.new(3), Object.new]
p owed.map { |v| total == v }
p owed.map { |v| three == v }
p owed.map { |v| v == three }
