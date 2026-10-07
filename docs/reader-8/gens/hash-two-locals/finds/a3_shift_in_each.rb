h = {a: 1, b: 2, c: 7}
g = h
m = {1 => 1}
g.merge!(m) if ARGV.size > 5
h.each { |_k, _v| h.shift }
p h.to_a
