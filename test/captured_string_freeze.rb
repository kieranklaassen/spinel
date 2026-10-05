# freeze as a statement on a shared String that a proc captures: the handle
# is in the cell outside the proc and in the capture inside it.

# frozen outside the proc, changed inside
s = "qr".dup
t = s
t.freeze
add = -> { t << "x" }
rep = -> { t.replace("z") }
[add, rep].each do |f|
  begin
    f.call
  rescue FrozenError => e
    p e.class
  end
end
p s, s.frozen?, t.frozen?, s.equal?(t)

# frozen inside the proc, changed outside
u = "qr".dup
v = u
fz = -> { v.freeze; 1 }
u << "s"
p fz.call
begin
  u << "x"
rescue FrozenError => e
  p e.class
end
begin
  v.concat("z")
rescue FrozenError => e
  p e.class
end
p u, u.frozen?, v.frozen?, u.equal?(v)

# a captured parameter
def seal(d)
  l = -> { d << "k" }
  l.call
  d.freeze
  l
end
c = "qr".dup
l = seal(c)
begin
  l.call
rescue FrozenError => e
  p e.class
end
p c, c.frozen?

# in a proc in a lambda, and one that does not run
a = "qr".dup
b = a
nest = -> { m = proc { b.freeze; nil }; m.call }
skip = -> { b.freeze if a.size > 5; 2 }
p skip.call, a.frozen?
a << "s"
nest.call
begin
  b.upcase!
rescue FrozenError => e
  p e.class
end
p a, a.frozen?, a.equal?(b)
