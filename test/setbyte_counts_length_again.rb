# setbyte can make two bytes one character, or one character two: a length
# asked for before it must not be answered again after.

# a plain String: three 7-bit bytes become one character and a byte
s = +"abc"
puts s.size, s[-1]
s.setbyte(0, 0xC3)
s.setbyte(1, 0xA9)
puts s.size, s.length, s.bytesize, s[0], s[-1], s.chars.size

# a counted String of two characters and two bytes becomes two characters
t = +"é12"
puts t.size
t.setbyte(2, 0xC3)
t.setbyte(3, 0xA9)
puts t.size, t.bytesize, t[1], t[-1], t[-1].bytesize

# one character of two bytes becomes two characters
v = +"éé"
puts v.size
v.setbyte(0, 0x41)
v.setbyte(1, 0x42)
puts v.size, v.bytesize, v[0], v[2]

# the same under two names
a = +"abcd"
b = a
puts a.size, b.size
a.setbyte(2, 0xC3)
a.setbyte(3, 0xA9)
puts a.size, b.size, b.bytesize, a[-1], b[2]

c = +"日ab"
d = c
puts d.size
d.setbyte(3, 0xC3)
d.setbyte(4, 0xA9)
puts c.size, d.size, c.bytesize, c[-1]

# in an instance variable
class Cell
  def initialize(x) @s = x end
  def poke(i, v) @s.setbyte(i, v) end
  def size; @s.size; end
  def last; @s[-1]; end
end
k = Cell.new(+"xyz")
puts k.size
k.poke(1, 0xC3)
k.poke(2, 0xA9)
puts k.size, k.last

# a 7-bit byte for a 7-bit byte changes no count
w = +"hello"
puts w.size
w.setbyte(0, 0x4A)
puts w.size, w

# bytes written while the String is binary are counted when it is text again
x = +"é12"
puts x.size
x.force_encoding("BINARY")
x.setbyte(2, 0xC3)
x.setbyte(3, 0xA9)
puts x.size
x.force_encoding("UTF-8")
puts x.size, x[-1]

y = +"abcd"
z = y
puts y.size
y.force_encoding("BINARY")
y.setbyte(0, 0xC3)
y.setbyte(1, 0xA9)
y.force_encoding("UTF-8")
puts y.size, z.size, z[0]
