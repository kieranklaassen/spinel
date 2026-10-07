def put(x, k, v)
  x[k] = v
end
h = Hash.new
g = h
f = g
e = f
h[1] = 2
put(g, "k", "s") if ARGV.size > 5
f[1] = 77
p h.to_a
p e.to_a
