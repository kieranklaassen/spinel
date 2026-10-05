# A call that answers a plain value and reads nothing but literals, made
# straight on a bare `Array.new`, answers as on the empty literal `[]`. As a
# receiver the constructor stayed untyped: `Array.new.join` and
# `Array.new.sum` answered nil, and `Array.new.include?(1)` raised
# NoMethodError "for unknown" at run time.

# the ones that answered nil with nothing said
p Array.new.join, Array.new.join("-")
p Array.new.sum, Array.new.sum(0.0), Array.new.sum(5)

# the ones that raised
p Array.new.include?(1), Array.new.index(1), Array.new.any?, Array.new.none?, Array.new.nil?
p Array.new.all?, Array.new.one?, Array.new.count(1), Array.new.any?(1)
p Array.new.at(0), Array.new.dig(0), Array.new.dig(0, 1), Array.new[0], Array.new[-1]
p Array.new.rindex(1), Array.new.find_index(:a), Array.new.member?("a"), Array.new.include?(nil)
p Array.new == nil, Array.new != 1, Array.new == "a", Array.new != :a
p Array.new.fetch(0, 1), Array.new.fetch(0, nil)
p Array.new.fetch(-1, :none), Array.new.fetch(2, 1.5)

# the ones that were right
p Array.new.first, Array.new.last, Array.new.min, Array.new.max
p Array.new.size, Array.new.length, Array.new.count, Array.new.empty?, Array.new.frozen?
p Array.new.inspect, Array.new.to_s

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

# a call outside the list is compiled as it was: a seed that `[]` does not
# answer, a block
p Array.new.sum(nil)
if ARGV.size > 5
  p(Array.new.rindex { |x| x })
end

# with an argument, or not as a receiver, nothing changes
p Array.new(2).push(1), Array.new(1, 0) << 4
g = Array.new
g << 7
p g
