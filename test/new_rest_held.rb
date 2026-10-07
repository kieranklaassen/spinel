# A rest array handed to `new` is held while the object is allocated.
#
# `Bag.new` builds an empty rest array in place as the constructor's
# argument and `Bag.new(*xs)` a copy of xs, and the constructor allocated
# the object before anything held it: initialize roots its parameters, but
# runs after. A collection at that allocation freed the array, and the
# object then kept whatever took its place.
#
# Each line is the number of objects that answer something else.

class Bag
  def initialize(*r) = @r = r
  def r = @r
  def add(v) = @r << v
end

# an argument ahead of the rest, a keyword rest after it
class Tagged
  def initialize(n, *r, **o)
    @n = n
    @r = r
    @o = o
  end
  def all = @r + [@n, @o.length]
end

# initialize inherited
class Sack < Bag
  def size = r.length
end

class Lost < StandardError
  def initialize(*r)
    super("lost")
    @r = r
  end
  def r = @r
end

class Pile < Array
  def initialize(*r) = @r = r
  def r = @r
end

# a yielding initialize handed a proc: the constructor allocates, a clone
# runs the body
class Counted
  def initialize(*r)
    @r = r
    @n = yield(r.length)
  end
  def all = @r + [@n]
end

# every object stays alive, so each one is a fresh allocation
keep = []
2000.times { keep << Bag.new }
keep.each_with_index { |b, i| b.add(i) }
bad = 0
keep.each_with_index { |b, i| bad += 1 unless b.r == [i] }
puts "no argument for the rest: #{bad}"

keep = []
2000.times do |i|
  xs = [i, i + 1]
  keep << Bag.new(*xs)
end
bad = 0
keep.each_with_index { |b, i| bad += 1 unless b.r == [i, i + 1] }
puts "a splat for the rest: #{bad}"

bad = 0
500.times do |i|
  s = "k#{i}"
  a = Tagged.new(i)
  b = Tagged.new(i, *[s, 1])
  bad += 1 unless a.all == [i, 0] && b.all == [s, 1, i, 0]
end
puts "an argument ahead of the rest: #{bad}"

bad = 0
500.times do |i|
  xs = [i, "b"]
  c = Sack.new(*xs)
  bad += 1 unless c.size == 2 && Sack.new.size == 0
end
puts "a rest, initialize inherited: #{bad}"

bad = 0
500.times do |i|
  xs = [i]
  e = Lost.new(*xs)
  bad += 1 unless e.r == [i] && Lost.new.r == [] && e.message == "lost"
end
puts "a rest of an exception class: #{bad}"

bad = 0
500.times do |i|
  xs = [i]
  s = Pile.new(*xs)
  s << i
  bad += 1 unless s.r == [i] && Pile.new.r == [] && s.length == 1
end
puts "a rest of an Array subclass: #{bad}"

bad = 0
500.times do |i|
  xs = [i, 2]
  pr = proc { |n| n + i }
  a = Counted.new(&pr)
  b = Counted.new(*xs, &pr)
  bad += 1 unless a.all == [i] && b.all == [i, 2, i + 2]
end
puts "a rest of a yielding initialize: #{bad}"

kinds = [Bag, Sack]
bad = 0
500.times do |i|
  b = kinds[i % 2].new
  b.add(i)
  bad += 1 unless b.r == [i]
end
puts "a rest through a class value: #{bad}"
