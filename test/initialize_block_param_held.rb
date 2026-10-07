# A block handed to `new` and kept by initialize(&blk) is held while the
# object is allocated.
#
# `Agg.new { |v| v + i }` builds the proc in place as the constructor's
# argument, and the constructor allocated the object before anything held
# the proc: initialize roots its block parameter, but runs after. A
# collection at that allocation freed the proc, and the object then called
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
