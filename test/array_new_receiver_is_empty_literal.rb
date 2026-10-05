# A call that answers a plain value, made straight on a bare `Array.new`,
# answers as on the empty literal `[]`. As a receiver the constructor stayed
# untyped: `Array.new.join` and `Array.new.sum` answered nil, and
# `Array.new.include?(1)` raised NoMethodError "for unknown" at run time.

# the ones that answered nil with nothing said
p Array.new.join, Array.new.join("-"), Array.new.pack("C*")
p Array.new.sum, Array.new.sum(0.0), Array.new.sum { |v| v }

# the ones that raised
p Array.new.include?(1), Array.new.index(1), Array.new.any?, Array.new.none?, Array.new.nil?
p Array.new.all?, Array.new.one?, Array.new.any? { |v| v }, Array.new.count(1)
p Array.new.at(0), Array.new.dig(0), Array.new[0], Array.new[-1]
p Array.new.find { |v| v }, Array.new.rindex(1), Array.new.index { |v| v }
p Array.new.inject(0) { |s, v| s + v }, Array.new.inject(:+), Array.new.reduce(1, :+)
p Array.new.each_with_object(0) { |v, a| a }, Array.new.detect { |v| v }, Array.new.member?(1)
p Array.new.fetch(0, 1), Array.new.fetch(0, nil), Array.new.fetch(-1, :none)

# the ones that were right
p Array.new.first, Array.new.last, Array.new.min, Array.new.max
p Array.new.size, Array.new.length, Array.new.count, Array.new.empty?, Array.new.frozen?
p Array.new.inspect, Array.new.to_s, Array.new == [], Array.new != [1]

# an operand is looked at and left as it was
s = String.new("a")
d = [1]
p Array.new.include?(s), Array.new.index(s), Array.new.join(s), Array.new == d
s << "!"
d << 2
p s, d

# the String such a call answers is its own
j = Array.new.join
k = Array.new.join
j << "x"
p j, k

class Tally
  def initialize
    @n = Array.new.size
    @text = Array.new.join
  end

  def add(v)
    @n += 1
    @text << v
  end

  def report = [@n, @text]
end
t = Tally.new
t.add("a")
t.add("b")
p t.report

# a reopened Array changes nothing
class Array
  def second = self[1]
end
p Array.new.first, [5, 6].second

# with an argument, or not as a receiver, nothing changes
p Array.new(2).push(1), Array.new(1, 0) << 4
g = Array.new
g << 7
p g
