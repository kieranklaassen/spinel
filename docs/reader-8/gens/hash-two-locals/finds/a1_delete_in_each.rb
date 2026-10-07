h = {a: 1, b: 2}
g = h
m = {1 => 2}
g.merge!(m) if ARGV.size > 5
h.each { |k, _v| h.delete(k) }
p h.to_a
