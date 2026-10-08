# spinel: int64
# include? / member? / index / find_index / rindex on an Integer array given a
# boxed number that is no Integer. Array asks `element == needle`, and a
# Float or a Rational can equal an Integer (1.0 == 1): the search answered
# "not there" without looking.

xs = [1, 2, 0, 1, 4611686018427387904, 9007199254740993]
row = [1.0, 2.0, -0.0, 4611686018427387904.0, Rational(2, 1), 1.5, 0.0 / 0.0,
       9007199254740992.0, Rational(3, 2), 2**70, 1, 9, "1", :s, nil, true]
row.each do |v|
  n = [v, :pad][0]
  p [xs.include?(n), xs.member?(n), xs.index(n), xs.find_index(n), xs.rindex(n), xs.count(n)]
end

# the needle out of a Hash, the answer as a condition
price = { list: 2.0, note: "each" }
puts "listed" if xs.include?(price[:list])
puts "not listed" unless xs.member?(price[:note])
p xs.index(price[:list])

# an Array in an instance variable, one built by <<, one that holds nil
class Stock
  def initialize = @ids = [10, 20, 30, 20]
  def at(id) = @ids.index(id)
  def last_at(id) = @ids.rindex(id)
  def has?(id) = @ids.include?(id)
end
s = Stock.new
order = [20.0, "20", 25.0]
order.each { |id| p [s.at(id), s.last_at(id), s.has?(id)] }
built = []
[3, 4, 5].each { |e| built << e }
p built.index(order[0] / 5), built.include?(order[2] / 5)
gaps = [1, nil, 0]
p gaps.index(row[2]), gaps.include?(row[0]), gaps.index(row[14]), gaps.rindex(row[1])

# an Integer Array with nil in a slot: -2**63 is that slot's word, no element
holes = [1, 2, 3].map { |e| e == 2 ? nil : e }
edge = [3.0, -(2.0**63), nil, Rational(6, 2), 2.0]
edge.each { |n| p [holes.include?(n), holes.index(n), holes.rindex(n)] }
