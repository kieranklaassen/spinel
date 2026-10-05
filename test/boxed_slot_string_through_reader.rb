# A String changed in place through the reader of a boxed slot -- a Struct
# member or an attr_reader's ivar that holds nil or another kind of value
# as well -- reaches the slot, as it does for a boxed local or ivar: the
# plain String in the box answers a new one, and the slot takes it back.
S = Struct.new(:x)
c = S.new
c.x = +"q"
c.x << "z"
p c.x
c.x << "a" << "b"
p c.x
p(c.x << "!")
c.x.upcase!
p c.x
p c.x.downcase!
p c.x.downcase!
c.x.replace("r")
p c.x

# a member that held an Integer first, appended to under a guard
T = Struct.new(:n, :s)
t = T.new(1, 2)
t.s = +"s"
t.s << "t" if t.s
t.s << "u"
t.s.capitalize!
p t

# an accessor that is nil until it is set, read through an ivar and self
class Note
  attr_accessor :text
  def initialize(text) = @text = text
  def add(s) = self.text << s
end
class Pad
  def initialize(n) = @n = n
  def go
    @n.text << "y"
    @n.text.swapcase!
    @n.text
  end
end
n = Note.new(nil)
n.text = +"x"
p Pad.new(n).go
n.add("w")
p n.text

# a Data member, and a frozen String there still refuses the append
D = Data.define(:x)
D.new(x: 1)
d = D.new(x: +"d")
d.x << "e"
p d
c.x.freeze
begin
  c.x << "f"
rescue FrozenError => e
  p e.class
end
p c.x

# an Array in such a slot is appended to as before
c.x = [1]
c.x << 2
p c.x
