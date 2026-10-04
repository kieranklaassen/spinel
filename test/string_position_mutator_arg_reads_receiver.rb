# insert, []= and slice! on a shared String whose argument reads the same
# String from a statement the argument hoists: a block's inlined loop, the
# parts of an interpolation. The mutator runs against a shadow copy declared
# inside its own block, so such an argument is evaluated first, ahead of the
# statement and on the String itself, as CRuby runs it before the call.

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
l = -> { b.insert(1, %w[x yy zzz].select { |w| w.size < b.size }.join); b.size }
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

# an arm that is not taken does not run its argument
r = k > 5 ? g.insert(0, [1].map { |x| puts "not run"; g.size.to_s }.join) : "no"
p r, f

# the block changes the String: by its own name, by its other name, in a
# method it calls; the read after the change sees it, and the change stays
def bump(w)
  w << "y"
end
m = "qrst".dup
n = m
n.insert(0, [1].map { |x| n << "a"; n.size.to_s }.join)
p m
n.insert(0, [1].map { |x| m << "b"; n.size.to_s }.join)
p m
n.insert(0, [1].map { |x| bump(m); n.size.to_s }.join)
p m, m.equal?(n)

# an earlier argument is read before a later one's block runs
n[n.size - 1, 1] = [1].map { |x| n << "c"; "z" }.join
p m
n[k, 1] = [1].map { |x| k += 1; n.size.to_s }.join
p m, k

# two Strings, one changed in the other's argument
o = "wxyz".dup
w = o
n.insert(0, [1, 2].map { |x| w.insert(0, [x].map { |y| (w.size + n.size + y).to_s }.join); w.size.to_s }.join)
p m, o, m.equal?(n), o.equal?(w)

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
