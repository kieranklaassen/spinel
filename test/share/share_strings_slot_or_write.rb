# Under --share-strings a String stored into a boxed slot is boxed as its
# handle, so an append through the slot reaches it. A slot written by
# `o.x ||= v`, `o.x &&= v`, `@x ||= v` or `@x &&= v` took a copy: only the
# plain write, the attribute writer and instance_variable_set were listed.

# an attribute nothing else writes: its slot is a box
class Box
  attr_accessor :x, :y
end

r = Box.new
r.x ||= +"ab"
r.x << "z"
p r.x

# through a second name for the String the slot holds
t = r.x
t << "y"
p r.x

# `&&=` on the slot that now holds one
r.x &&= +"cd"
r.x << "!"
p r.x, t

# the value of the write is the slot's String
(r.y ||= +"v") << "w"
p r.y

# two objects, one String
q = Box.new
q.x ||= r.x
q.x << "?"
p r.x, q.x

# `self.x ||=` in a method
class Memo
  attr_accessor :x

  def fill
    self.x ||= +"m"
    self.x << "1"
    self
  end
end

p Memo.new.fill.fill.x

# an instance variable whose slot another kind made a box, appended to
# through its reader
class Slot
  attr_reader :x

  def initialize
    @x = false
  end

  def fill
    @x ||= +"iv"
    self
  end

  def swap
    @x &&= +"and"
    self
  end
end

s = Slot.new.fill
s.x << "+"
p s.x
s.swap.x << "-"
p s.x

# a Struct member
Pair = Struct.new(:left, :right)
pr = Pair.new
pr.left ||= +"l"
pr.left << "L"
pr.right ||= pr.left
pr.right << "R"
p pr.left, pr.right
