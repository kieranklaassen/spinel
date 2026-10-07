# A local read out of an Array that map! (or collect!) rewrote with another
# kind of element holds the element itself. The receiver is made the general
# Array after the locals were typed from their writes, so `r = t.first` was
# typed from the Array as it began: a Symbol read as a Float raised
# TypeError, a String read as an Integer printed 0.
t = [1.5, 2.5]
t.map! { |e| e == t[0] ? :k : e }
r = t.first
p r
s = t.last
p s
a, b, c = t
p a
p b
p c

# an Integer Array that takes a String, read every way
n = [1, 2]
n.map! { |e| e == n[0] ? "s" : e }
x = n[0]
p x
y = n.fetch(1)
p y
z = n.find { |e| e != 2 }
p z
n.each { |e| w = e; p w }
u = n.last
v = u
p v
p x.to_s + "!"

# collect!, a block of two statements, and a numbered parameter
q = ["a", "b"]
q.collect! { |e| e == q[0] ? 7 : e }
h = q.first
p h
m = [:a, :b]
m.map! { |e| k = e; k == m[1] ? 2.5 : k }
g = m.last
p g
o = [3, 4]
o.map! { _1 == o[0] ? :three : _1 }
f = o.shift
p f
p o

# inside a method, and inside a block
def run
  t = [1, 2]
  t.map! { |e| e == t[0] ? "one" : e }
  r = t.first
  r
end
p run
d = [1.5, 2.5]
[0].each { d.map! { |e| e == d[1] ? "x" : e } }
j = d.pop
p j

# an alias of the receiver, and a second map! of the same kind
l = [1, 2]
l2 = l
l2.map! { |e| e == l2[0] ? :one : e }
i = l.first
p i
l.map! { |e| e }
p l

# its own kind, and a map! that never runs: the values are as they were
w = [1, 2]
w.map! { |e| e + 1 }
aa = w.first
p aa + 1
c2 = [1, 2]
c2.map! { |e| "s" } if ARGV.size > 5
bb = c2.last
p bb
