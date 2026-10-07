h = {a: 1, b: 2}
h[:k] = "s"
t = 0
h.each { |_k, v| t += v }
p t
