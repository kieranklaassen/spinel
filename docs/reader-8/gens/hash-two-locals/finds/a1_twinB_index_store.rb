h = {a: 1, b: 2}
g = h
g[1] = 2 if ARGV.size > 5
h.each { |k, _v| h.delete(k) }
p h.to_a
