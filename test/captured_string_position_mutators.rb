# slice!, setbyte, insert, []= and clear on a shared String that a proc
# captures. These five re-run the value arm against a shadow copy and swap
# the handle's buffer; the handle is in the proc's capture inside the proc
# and in the cell outside it, not in a plain C local.

# inside a lambda, as the lambda's value
s = "qrst".dup
t = s
sl = -> { t.slice!(0) }
sb = -> { t.setbyte(0, 90) }
ins = -> { t.insert(1, "ab") }
set = -> { t[-1] = "yz" }
p sl.call, s
p sb.call, s
ins.call
p s
p set.call, s
p s.equal?(t)

# inside a lambda, as statements
u = "qrst".dup
v = u
st = -> { v.slice!(0, 2); v.setbyte(-1, 33); v.insert(0, "k"); v[1] = "LM"; v.size }
p st.call, u, u.equal?(v)
cl = -> { v.clear; 0 }
p cl.call, u, u.equal?(v)

# outside the lambda that captures it
a = "qrst".dup
b = a
ap = -> { b << "!" }
b.slice!(0)
b.setbyte(0, 82)
b.insert(-1, "uv")
b[0, 1] = "x"
r = b.slice!(1)
ap.call
p r, a, a.equal?(b)
b.clear
ap.call
p a

# a captured parameter, and a local bound to one
def trim(d)
  l = -> { d.slice!(0); d.insert(0, "<") }
  l.call
  nil
end

def stamp(d)
  t = d
  l = -> { t.setbyte(0, 35); t[1] = "--" }
  l.call
end
c = "qrst".dup
trim(c)
p c
p stamp(c), c

# a proc, a nested lambda, a Fiber body
e = "qrstuv".dup
f = e
pr = proc { f.slice!(0) }
pr.call
pr.call
nest = -> { inner = -> { f.insert(0, "n") }; inner.call }
nest.call
Fiber.new { f[1] = "F"; f.setbyte(0, 78) }.resume
p e, e.equal?(f)

# an argument that reads the receiver, and another captured String
g = "qrst".dup
h = g
i = "ab".dup
j = i
mix = -> { h.insert(1, j); j.slice!(0); h.setbyte(0, j.getbyte(0)); h[2] = h }
mix.call
p g, i, g.equal?(h), i.equal?(j)

# the frozen check and the index check still run
k = "qr".dup
m = k
fz = [-> { m.slice!(0) }, -> { m.setbyte(0, 90) }, -> { m.insert(0, "z") }, -> { m[0] = "z" }]
ix = [-> { m[5] = "z" }, -> { m.insert(9, "z") }, -> { m.setbyte(7, 65) }]
ix.each do |q|
  begin
    q.call
  rescue IndexError => err
    p err.class
  end
end
k.freeze
fz.each do |q|
  begin
    q.call
  rescue FrozenError => err
    p err.class
  end
end
p k, m

# many calls, each replacing the buffer
n = "qrst".dup
o = n
grow = -> { o.insert(0, "zzz"); o.slice!(1); o.setbyte(0, 65 + o.size % 26); o[0, 0] = "k" }
200.times { grow.call }
p n.size, n[0, 8], n.equal?(o)
