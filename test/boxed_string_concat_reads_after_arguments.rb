# A String read out of a Hash or a mixed Array sits behind a shared handle.
# concat and prepend on it read its text after their arguments have run, as
# CRuby does: an argument that grows the receiver moves its bytes.
def big(x, n) = (x << ("y" * n); "a")

# the one argument grows the receiver
g = { a: +"q", b: +"q", c: +"q", d: +"q", e: +"q" }
pad = (1..40).map { |i| "pad" + i.to_s }
m = g[:a]
m.concat((m << ("z" * 300); "w"))
p g[:a].size, g[:a][0, 2], g[:a][-3, 3]

# a method the argument calls grows it
a = [+"q", 1]
pad2 = (1..40).map { |i| "pad" + i.to_s }
v = a[0]
v.concat(big(v, 400))
p a[0].size, a[0][0, 2], a[0][-3, 3]

# a lambda grows it
f = -> { v << ("v" * 600); "l" }
v.concat(f.call)
p a[0].size, a[0][-3, 3]

# the receiver is the element read itself
g[:b].concat((g[:b] << ("z" * 300); "w"))
p g[:b].size, g[:b][-3, 3]

# several arguments, the last one grows it
n = g[:c]
n.concat("n", big(n, 500))
p g[:c].size, g[:c][0, 2], g[:c][-3, 3]

# the call's value
r = n.concat((n << ("+" * 700); "="))
p r.size, r[-2, 2], g[:c].size

# prepend
g[:d].prepend((g[:d] << ("z" * 300); "w"))
p g[:d].size, g[:d][0, 3]
k = g[:e]
k.prepend("n", big(k, 300))
p g[:e].size, g[:e][0, 4]
p pad.size + pad2.size

# a parameter that takes a String on one call and an Integer on another
def tail(s)
  s.concat((s << ("z" * 300); "w"))
  s
end
e = { a: +"q" }
p tail(e[:a]).size, e[:a][-3, 3]
begin
  tail(5)
rescue TypeError, NoMethodError
  p :raised
end

# many rounds, the receiver growing each time
t = { a: +"" }
o = t[:a]
60.times { |i| o.concat((o << ("r" * i); ">")) }
p t[:a].size, t[:a][0, 12], t[:a][-8, 8]
