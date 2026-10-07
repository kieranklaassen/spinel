h = {1 => 1, 2 => 2}
g = h
g["k"] = 1 if ARGV.size > 5
h.each { |k, _v| h.delete(k) }
p h.to_a
