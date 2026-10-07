# Flag-only: without the flag (as on master) the holder takes a copy and
# misses the change.
# A method's own block parameter called in the method (`blk.call`,
# `blk.()`) is spliced in place where its literal block is, as a `yield`
# is: no proc hands back a box there. What the block answers takes the
# route a yield's answer takes: a new String's own handle, the handle of a
# variable's String, nil.
class Box
  def initialize(r, &blk)
    @s = blk.call(r)
  end
  def s = @s
end

class Slot
  attr_accessor :s
  def set(r, &blk)
    @s = blk.(r)
    self
  end
  def put(r, &blk)
    self.s = blk.call(r)
    self
  end
end

def count
  yield
end

# a new String, in a constructor spliced under another block
puts count { n = Box.new(3) { |r| "hi " * r }; n.s }

# a variable's String: the holder and the variable are one String
x = +"hi"
n = Box.new(3) { |r| x }
n.s << "!"
p x
x << "?"
p n.s

m = Slot.new.set(2) { |r| x }
m.s << "+"
p x, n.s
m.put(1) { |r| x }
x << "-"
p m.s

# a String or nil
k = Box.new(1) { |r| r > 2 ? "big" : nil }
p k.s
k = Box.new(5) { |r| r > 2 ? "big" : nil }
p k.s

# a block handed over as a proc is called, not spliced
class Held
  def initialize(r, &blk)
    @s = blk.call(r)
  end
  def s = @s
end
pr = proc { |r| x }
q = Held.new(3, &pr)
q.s << "#"
p x
