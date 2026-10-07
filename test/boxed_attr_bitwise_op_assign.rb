# `obj.v &= x`, `|=` and `^=` on an attribute whose slot is boxed: the slot
# was read as an Integer whatever it held, so "s" answered 0 or 1, 2.5
# answered from 2, true from 1, and nil raised where Ruby answers false or
# true. The slot now takes the operator of the value it holds, as a boxed
# local does.

def t(s)
  r = yield
  puts "#{s}: #{r.inspect}"
rescue NoMethodError, TypeError => e
  puts "#{s}: #{e.class}"
end

class Box
  attr_accessor :v
  def initialize(v) = @v = v
  def and_self(x)
    self.v &= x
    v
  end
  def or_self(x)
    self.v |= x
    v
  end
  def xor_self(x)
    self.v ^= x
    v
  end
end

vals = [6, nil, false, true, "s", 2.5, :sy, [3, 1]]
vals.each do |v|
  t("#{v.inspect} &= 1") { b = Box.new(v); b.v &= 1; b.v }
  t("#{v.inspect} |= 1") { b = Box.new(v); b.v |= 1; b.v }
  t("#{v.inspect} ^= 1") { b = Box.new(v); b.v ^= 1; b.v }
end

# the right operand boxed too, and a truth value on the right
ops = [3, true, nil, [1, 9]]
[6, nil, false, true, [3, 1]].each do |v|
  ops.each do |x|
    t("#{v.inspect} &= #{x.inspect}") { b = Box.new(v); b.v &= x; b.v }
    t("#{v.inspect} |= #{x.inspect}") { b = Box.new(v); b.v |= x; b.v }
    t("#{v.inspect} ^= #{x.inspect}") { b = Box.new(v); b.v ^= x; b.v }
  end
end

# through self, and through a receiver that is boxed itself
[6, nil, true, "s"].each do |v|
  t("self #{v.inspect} &=") { Box.new(v).and_self(3) }
  t("self #{v.inspect} |=") { Box.new(v).or_self(3) }
  t("self #{v.inspect} ^=") { Box.new(v).xor_self(3) }
  r = [Box.new(v), 0][ARGV.size]
  t("boxed #{v.inspect} &=") { r.v &= 3; r.v }
  t("boxed #{v.inspect} |=") { r.v |= 3; r.v }
  t("boxed #{v.inspect} ^=") { r.v ^= 3; r.v }
end

# the value of the statement, and the slot after a raise
b = Box.new(nil)
t("value") { (b.v |= 1) }
b = Box.new("s")
t("kept") { begin; b.v &= 1; rescue NoMethodError; end; b.v }

# the slot is read before the right operand runs, which may write it
class Box
  def bump
    @v = 12
    5
  end
  def swap
    @v = [9]
    20.times { |i| [i, i.to_s] }
    [[1, 9], 0][ARGV.size]
  end
end
t("read first ^=") { b = Box.new(6); b.v ^= b.bump; b.v }
t("read first |=") { b = Box.new(6); b.v |= b.bump; b.v }
t("read first &=") { b = Box.new(6); b.v &= (b.v = 9; 3); b.v }
t("read first nil") { b = Box.new(nil); b.v &= (b.v = 6; 3); b.v }
t("read first String") { b = Box.new("s"); b.v |= (b.v = 6; 3); b.v }
t("read first Array") { b = Box.new([3, 1]); b.v &= b.swap; b.v }
r = [Box.new(6), 0][ARGV.size]
t("read first boxed") { r.v ^= r.bump; r.v }

# an Integer attribute that may be nil keeps its own slot
class Count
  attr_accessor :n
  def initialize(n) = @n = n
end
c = Count.new(6)
Count.new(1).n = nil
t("Integer slot") { c.n &= 3; c.n |= 8; c.n ^= 1; c.n }
