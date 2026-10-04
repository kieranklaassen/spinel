# insert, []= and slice! on a shared String whose argument reads the same
# String from a statement the argument hoists: a block's inlined loop, the
# parts of an interpolation. The mutator runs against a shadow copy, and the
# hoisted statements read that shadow, so they run after it is declared and,
# arguments of the call, before its frozen check.

# a statement
s = "qrst".dup
t = s
t.insert(0, [1, 2].map { |x| (t.size + x).to_s }.join)
p s
t[0] = %w[a bb ccc dddddddd].select { |w| w.size < t.size }.join
p s
t[0, 3] = "<#{t.size}#{[1, 2].map { |x| x + t.size }.join}>"
p s
t.slice!([1, 2].map { |x| x + t.size }.join.size % 3)
p s, s.equal?(t)

# as a value
u = "qrst".dup
v = u
r = v.insert(0, [1, 2].map { |x| (v.size + x).to_s }.join)
p r, u
q = v.slice!([3].map { |x| x + v.size }.join.size)
p q, u, u.equal?(v)

# inside a lambda, and on a parameter
a = "qrst".dup
b = a
l = -> { b.insert(1, [1, 2].map { |x| (b.size * x).to_s }.join); b.size }
p l.call, a, a.equal?(b)

def pad(d)
  d[0] = "#{d.size}#{[1].map { |x| x + d.size }.join}"
  d.insert(-1, %w[x yy zzz].select { |w| w.size * 3 < d.size }.join)
  nil
end
c = "qrst".dup
e = c
pad(c)
p c, c.equal?(e)

# an argument that hoists and does not read the receiver
f = "qrst".dup
g = f
k = 3
g.insert(0, [1, 2].map { |x| (k + x).to_s }.join)
p f, f.equal?(g)

# a frozen receiver: the argument runs, then the call raises
h = "qrst".dup
i = h
i.freeze
begin
  i.insert(0, [1, 2].map { |x| puts "block #{x}"; (i.size + x).to_s }.join)
rescue FrozenError => e
  p e.class
end
begin
  z = i.slice!([3].map { |x| puts "block #{x}"; x + i.size }.join.size)
  p z
rescue FrozenError => e
  p e.class
end
p h, h.equal?(i)
