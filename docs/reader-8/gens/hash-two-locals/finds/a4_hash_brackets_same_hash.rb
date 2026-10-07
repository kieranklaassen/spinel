h = {a: 1}
g = h
m = {1 => 1}
g.merge!(m) if ARGV.size > 5
c = Hash[g]
c[:n] = 5
p g.to_a
