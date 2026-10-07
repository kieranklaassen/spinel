class Bag
  def initialize = @xs = [4, 5, 6]
  def has?(n) = @xs.include?(n)
  def at(n) = @xs.index(n)
  def last_at(n) = @xs.rindex(n)
end
b = Bag.new
row = [5.0, Rational(6, 1), 4.5, "5", nil, 6]
row.each { |n| p [b.has?(n), b.at(n), b.last_at(n)] }
