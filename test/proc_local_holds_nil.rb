# A proc literal kept in a local that holds nil as well (`f = nil` first) is
# typed from the calls through the local, as one in a local written once is.
f = nil
f = ->(s) { s.length }
p f.call("wxyz")

g = nil
g = proc { |s| s.size }
p g.call("wxyz")

h = nil
h = ->(x) { x * 2 }
p h.call(1.5)
p h.call(21)

# set under a condition, and as one arm of a conditional
k = nil
k = ->(a) { a.first } if ARGV.empty?
p k.call([7, 8])

t = ARGV.empty? ? ->(s) { s.to_s } : nil
p t.call(:abc)

u = if ARGV.size > 5 then nil else proc { |s| s.sum } end
p u.call(1..3)

# a parameter, a multiple assignment beside it, and nil afterwards
def fire(f)
  f = ->(s) { s + "!" } if f.nil?
  f.call("go")
end
p fire(nil)
p fire(->(s) { s * 2 })

a, b = nil, nil
a = ->(s) { s[:a] }
p a.call({ a: 1 }), b

w = ->(s) { s.size }
p w.call("abc")
w = nil
p w.nil?

# the other ways to call it
c = nil
c = proc { |s| s.upcase }
p c.("ab"), c.yield("ef"), c&.call("gh"), c === "ij"

# a proc that leaves its name is called from where no call through the
# name shows, and keeps reading its argument as before
m = nil
n = (m = ->(s) { s.frozen? })
p n.call(5), m.call("x")

o = nil
o = ->(s) { s.frozen? }
q = o
p q.call(5), o.call("x")

# fed its own result, the proc is handed a boxed value
r = nil
r = ->(s) { s + "!" }
v = "a"
3.times { v = r.call(v) }
p v
