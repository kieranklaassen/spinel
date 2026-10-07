h = {a: 1}
g = h
g[1] = 1 if ARGV.size > 5
c = Hash[g]
c[:n] = 5
p g.to_a
