h = {a: "x", b: "y"}
h[:k] = 1
t = ""
h.each { |_k, v| t += v }
p t
