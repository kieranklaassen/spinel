# An append keeps what is known of a String's length instead of forgetting
# it, so every answer here comes after a length was asked for and the bytes
# then changed: by an append, or by a setbyte that an append follows.

# 7-bit, then one character of two bytes, then 7-bit again
s = +"ab"
puts s.size
s << "cd"
puts s.size, s[-1]
s << "é"
puts s.size, s.bytesize, s[-1], s[-2, 2]
s << "x"
puts s.length, s.bytesize, s[-1], s[0]

# a counted String of several characters grows by characters
t = +"日本"
puts t.size
t << "語"
puts t.size, t.bytesize, t[-1]
t << "go" << "é"
puts t.size, t.bytesize, t[-1], t[-3, 2]

# bytes that are no character alone count as bytes, until an append completes them
h = +"ab\xC3"
puts h.size, h.valid_encoding?
h << "\xA9"
puts h.size, h.bytesize, h.valid_encoding?, h[-1]
h << "!"
puts h.size

# one character arriving in two appends, on a String already counted
u = +"\u00e9"
puts u.size
u << "\xC3"
u << "\xA9"
puts u.size, u.bytesize, u[-1] == u[0]
u << "z"
puts u.size, u[-1]

# one String under two names
a = +"xy"
b = a
puts a.size
b << "é"
puts a.size, a.bytesize, b[-1]
a << "z"
puts b.size, b[-1]

# appended to by a method it is handed to
def add(buf, x) buf << x end
c = +"12"
puts c.size
add(c, "3")
puts c.size
add(c, "é")
puts c.size, c.bytesize, c[-1]

# in an instance variable
class Out
  def initialize; @o = +""; end
  def add(x) @o << x; @o.size end
  def last; @o[-1]; end
end
o = Out.new
puts o.add("ab"), o.add("é"), o.add("cd"), o.last

# setbyte makes two bytes one character; an append follows before the next read
m = +"abc"
puts m.size
m.setbyte(0, 0xC3)
m.setbyte(1, 0xA9)
puts m.size
m << "x"
puts m.size, m.bytesize, m[0]

n = +"é12"
k = n
puts n.size
n.setbyte(2, 0xC3)
n.setbyte(3, 0xA9)
n << "x"
puts n.size, k.size, n.bytesize, n[1]

# replace, clear and prepend still forget
r = +"abc"
q = r
puts r.size
r.replace("é")
r << "x"
puts r.size, r.bytesize
r.clear
r << "éé"
puts r.size, q.bytesize
r.prepend("日")
r << "!"
puts r.size, r[0], r[-1]

# binary bytes count one each whatever is appended
z = "ab".b
puts z.size
z << "\xFF".b
z << "cd"
puts z.size, z.bytesize

# the loop this is for
buf = +""
total = 0
2000.times { |i| buf << "a#{i % 10}"; total += buf.size }
puts total, buf.size
w = +"é"
total = 0
2000.times { |i| w << "bé"; total += w.size }
puts total, w.size, w.bytesize
