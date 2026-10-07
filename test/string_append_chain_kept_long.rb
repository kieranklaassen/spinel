# An append chain of 64 links or more kept in a local. `t = s << a << ...`
# is s itself, so t names the same String. The walk that finds s gave up
# after 64 steps: t became a copy, and what was appended through t never
# reached s.
s = +"b"
t = s << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a"
t << "!"
p t.size, s.size, t.equal?(s)

# concat links, and a longer chain
c = +"c"
d = c.concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy").concat("xy")
d << "!"
p d.size, c.size, c[-3, 3]

# a String a method has appended to
def mark(str) = str << "!"
m = +"m"
mark(m)
n = m << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a"
n << "?"
p m.size, m.equal?(n), m[-2, 2]

# in a method, with an interpolation among the links
def build(k)
  buf = +"<"
  out = buf << "#{k}" << "," << "#{k}" << "," << "#{k}" << "," << "#{k}" << "," << "#{k}" << "," << "#{k}" << "," << "#{k}" << "," << "#{k}" << "," << "#{k}" << "," << "#{k}" << "," << "#{k}" << "," << "#{k}" << "," << "#{k}" << "," << "#{k}" << "," << "#{k}" << "," << "#{k}" << "," << "#{k}" << "," << "#{k}" << "," << "#{k}" << "," << "#{k}" << "," << "#{k}" << "," << "#{k}" << "," << "#{k}" << "," << "#{k}" << "," << "#{k}" << "," << "#{k}" << "," << "#{k}" << "," << "#{k}" << "," << "#{k}" << "," << "#{k}" << "," << "#{k}" << "," << "#{k}" << "," << "#{k}" << ","
  out << ">"
  buf
end
p build(7).size, build(7)[-3, 3]

# `+=` after such a chain makes a new String of the local's
u = +"u"
v = u << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a"
v += "x"
v << "y"
p u.size, v.size, u.equal?(v)

# 300 links: one append a link on the same String. Nested a link deep, the C
# is past what clang takes (256 levels).
g = +"g"
h = g << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a"
h << "!"
p g.size, h.equal?(g)

# right before: 63 links
e = +"e"
f = e << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a"
f << "!"
p f.size, e.size
