# A call that stores nothing, made straight on a bare `Array.new`, answers as
# on the empty literal `[]`. As a receiver the constructor stayed untyped:
# `Array.new + [1]`, `Array.new.sort` and `Array.new.join` answered nil, and
# `Array.new.map { }` raised NoMethodError "for unknown" at run time.

# the ones that answered nil with nothing said
p Array.new + [1], Array.new - [1], Array.new * 2
p Array.new.sort, Array.new.reverse, Array.new.uniq, Array.new.compact, Array.new.flatten
p Array.new.dup, Array.new.to_a, Array.new.itself, Array.new.freeze
p Array.new.join, Array.new.sum, Array.new.pack("C*")

# the ones that raised
p Array.new.map { |v| v }, Array.new.select { |v| v }, Array.new.each { |v| v }
p Array.new.include?(1), Array.new.index(1), Array.new.any?, Array.new.none?, Array.new.nil?
p Array.new.take(1), Array.new.drop(1), Array.new.first(2), Array.new.zip([1]), Array.new.rotate
p Array.new.tally.size, Array.new.minmax, Array.new.inject(0) { |s, v| s + v }
p Array.new.fetch(0, 1), Array.new.dig(0), Array.new.clear, Array.new.delete(1)
p Array.new | [1], Array.new & [1], Array.new.to_h, Array.new.partition { |v| v }

# the ones that were right
p Array.new.first, Array.new.last, Array.new.min, Array.new.pop
p Array.new.size, Array.new.empty?, Array.new.frozen?, Array.new.class

# the array such a call answers is its own, and takes what is stored later
b = Array.new + [1]
c = Array.new + [1]
c << 2
p b, c, b.equal?(c)
d = Array.new.dup
d << "s"
e = Array.new.sort
e << 1.5
p d, e
s = String.new
f = Array.new.reverse
f << s
s << "x"
p f

class Bag
  def initialize
    @a = Array.new + [1]
  end

  def add(v) = @a << v
  def sum = @a.sum
end
bag = Bag.new
bag.add(2)
p bag.sum

# a reopened Array is still Array.new's class
class Array
  def second = self[1]
end
p((Array.new + [5, 6]).second)

# with an argument, or not as a receiver, nothing changes
p Array.new(2).push(1), Array.new(1, 0) << 4
g = Array.new
g << 7
p g
