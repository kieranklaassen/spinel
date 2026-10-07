h = {a: 1, b: 2}
g = h
g["k"] = "s"
t = 0
h.each { |_k, v| t += v }
p t
