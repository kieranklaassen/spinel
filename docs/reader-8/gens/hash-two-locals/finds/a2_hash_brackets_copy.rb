h = {a: 1, b: 2}
g = h
m = {1 => 2}
g.merge!(m) if ARGV.size > 5
c = Hash[h]
c[:n] = 5
p h.to_a
p c.equal?(h)
