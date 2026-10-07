# A rest array and a block handed to `new` are held while the object is
# allocated.
#
# `Agg.new { |v| v + i }` builds the proc in place as the constructor's
# argument, `Bag.new` an empty rest array and `Bag.new(*xs)` a copy of xs,
# and the constructor allocated the object before anything held them:
# initialize roots its parameters, but runs after. A collection at that
# allocation freed the proc or the array, and the object then kept
# whatever took its place.
#
# Each line is the number of objects that answer something else.

class Agg
  def initialize(&blk) = @blk = blk
  def feed(v) = @blk.call(v)
  def given? = !@blk.nil?
end

# another argument ahead of the block
class Scaled
  def initialize(n, &blk)
    @n = n
    @blk = blk
  end
  def feed(v) = @blk.call(v) + @n
end

# initialize inherited
class Child < Agg
  def twice(v) = feed(feed(v))
end

# the block handed on by super
class Grand < Agg
  def initialize(n, &blk)
    super(&blk)
    @n = n
  end
  def more(v) = feed(v) + @n
end

class Oops < StandardError
  def initialize(msg, &blk)
    super(msg)
    @blk = blk
  end
  def fix(v) = @blk.call(v)
end

class Stack < Array
  def initialize(&blk)
    super()
    @blk = blk
  end
  def top(v) = @blk.call(v)
end


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
2000.times { |i| keep << Agg.new { |v| v + i } }
bad = 0
keep.each_with_index { |b, i| bad += 1 unless b.feed(1) == i + 1 }
puts "kept in a list: #{bad}"

bad = 0
500.times do |i|
  b = Agg.new { |v| v + i }
  bad += 1 unless b.feed(1) == i + 1 && b.given?
end
puts "one at a time: #{bad}"

bad = 0
500.times do |i|
  s = "k#{i}"
  b = Scaled.new(i) { |v| v + s.length }
  bad += 1 unless b.feed(1) == 1 + s.length + i
end
puts "an argument ahead of the block: #{bad}"

bad = 0
500.times do |i|
  c = Child.new { |v| v + i }
  bad += 1 unless c.twice(1) == 2 * i + 1
end
puts "initialize inherited: #{bad}"

bad = 0
500.times do |i|
  g = Grand.new(i) { |v| v + i }
  bad += 1 unless g.more(1) == 2 * i + 1
end
puts "handed on by super: #{bad}"

bad = 0
500.times do |i|
  e = Oops.new("m#{i}") { |v| v + i }
  bad += 1 unless e.fix(1) == i + 1 && e.message == "m#{i}"
end
puts "an exception class: #{bad}"

bad = 0
500.times do |i|
  s = Stack.new { |v| v + i }
  s << i
  bad += 1 unless s.top(1) == i + 1 && s.length == 1
end
puts "an Array subclass: #{bad}"

bad = 0
500.times do |i|
  pr = proc { |v| v + i }
  b = Agg.new(&pr)
  bad += 1 unless b.feed(1) == i + 1
end
puts "a proc passed with &: #{bad}"

puts "no block given: #{Agg.new.given?}"

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
