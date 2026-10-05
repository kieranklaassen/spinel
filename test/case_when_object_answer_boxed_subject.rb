# `when obj` beside a boxed subject asks the object's own ===, whatever
# kind of value it answers. Only a === answering a boolean or a boxed
# value was asked: one answering an Integer, a Float, a String, an Array
# or an object (or nil) was compared with == instead and never matched.
class Count
  def ===(o) = o ? 1 : nil
end

class Zero
  def ===(o) = o.is_a?(Integer) ? 0 : nil
end

class Ratio
  def ===(o) = o.is_a?(Integer) ? 0.0 : nil
end

class Name
  def ===(o) = o.is_a?(Integer) ? "" : nil
end

class Itself
  def ===(o) = o.is_a?(Integer) ? self : nil
end

class List
  def ===(o) = o.is_a?(Integer) ? [] : nil
end

class Above
  def initialize(n) = @n = n
  def raise_to(n) = @n = n
  def ==(o) = o.is_a?(Integer) && o > @n ? o - @n : nil
end

class Child < Zero; end

class Log
  def initialize = @seen = 0
  def seen = @seen
  def ===(o)
    @seen += 1
    nil
  end
end

def maybe(f) = (f ? Zero.new : nil)

subjects = [true, false, nil, 3, "s", 2.5]

subjects.each do |v|
  case v
  when Count.new then puts "count hit"
  else puts "count miss"
  end
end

p subjects.map { |v| case v when Zero.new then :hit else :miss end }
p subjects.map { |v| case v when Ratio.new then :hit else :miss end }
p subjects.map { |v| case v when Name.new then :hit else :miss end }
p subjects.map { |v| case v when Itself.new then :hit else :miss end }
p subjects.map { |v| case v when List.new then :hit else :miss end }

# its == when it has no === of its own
above = Above.new(1)
above.raise_to(2)
p subjects.map { |v| case v when above then :hit else :miss end }

# inherited, and held in a local
child = Child.new
subjects.each do |v|
  case v
  when "s" then puts "string"
  when child then puts "child hit"
  else puts "child miss"
  end
end

# an arm that may be nil matches a nil subject alone
p subjects.map { |v| case v when maybe(false) then :hit else :miss end }
p subjects.map { |v| case v when maybe(true) then :hit else :miss end }

# one that answers nil on every path is called and is no match
log = Log.new
p subjects.map { |v| case v when log then :hit else :miss end }
p log.seen
