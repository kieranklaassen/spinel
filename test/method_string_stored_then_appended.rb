# A String a method of an object builds, stored in an Array or a Hash and
# appended to through it: the element is that new String, and the object is
# left as it was. The element was boxed as a shared String around the plain
# one the method answered: the C did not build with clang, and with gcc the
# append ended in SIGSEGV.

class K
  attr_reader :x
  def initialize(x) = @x = x
  def plus = @x + "a"
  def lit = "lit".dup
  def copy = @x.dup
  def show = "<#{@x}>"
  def to_s = "K(#{@x})"
  def tag(t) = t + @x
  def up = @x.upcase
  def pad = @x.center(5, "*")
end
P = Struct.new(:x)
class P
  def plus = x + "a"
end
class N
  def initialize(n) = @n = n
  def label = @n.to_s
  def padded = @n.to_s.rjust(3, "0")
end
class Holder
  attr_reader :list
  def initialize(c) = @list = [c.plus]
  def bump = @list[0] << "z"
end

c = K.new("q".dup)

# an Array literal, a Hash literal
z = [c.plus]
z[0] << "z"
p z, c.x
h = { k: c.plus }
h[:k] << "z"
p h.to_a, c.x

# each way a method builds its String
z = [c.lit, c.copy, c.show, c.to_s, c.tag("t")]
z[0] << "0"
z[1] << "1"
z[2] << "2"
z[3] << "3"
z[4] << "4"
p z, c.x

# a String method that always answers a new String
u = [c.up, c.pad]
u[0] << "0"
u[1] << "1"
p u, c.x

# beside other values
z = [1, c.plus]
z[1] << "z"
p z, c.x

# stored by a push and by an element assignment
z = []
z << c.plus
z.push(c.copy)
z.last << "z"
z.first.upcase!
p z, c.x
z = ["a".dup]
z[0] = c.plus
z[0].concat("z")
p z, c.x
h = {}
h[:k] = c.show
h[:k].replace("new")
p h.to_a, c.x

# appended to by a block
z = [c.plus, c.plus]
z.each { |e| e << "!" }
p z, c.x

# in an Array an instance variable holds
hd = Holder.new(c)
hd.bump
p hd.list, c.x

# a method a Struct defines
s = P.new("q".dup)
z = [s.plus]
z[0] << "z"
p z, s.x

# a String built from a number
n = N.new(7)
z = [n.label]
z[0] << "z"
p z
w = [n.padded]
w[0] << "z"
p w

# a method that answers nil where the String it builds from is nil: the
# element is nil
class O
  def initialize(x) = @x = x
  def up = @x&.upcase
  def copy = @x.dup
end
o = O.new(nil)
q = O.new("q".dup)
z = [o.up, q.up]
z[1] << "z"
p z
z = []
z << o.copy
z.push(q.copy)
z.each { |e| e << "!" if e }
p z
h = { a: o.up, b: q.up }
h[:b] << "z"
p h.to_a

# a subclass whose own method builds its String too
class L < K
  def plus = @x + "b"
end
def both = [K.new("p".dup), L.new("q".dup)]
b = both
z = [b[0].plus, b[1].plus]
z.each { |e| e << "!" }
p z, b[0].x, b[1].x
