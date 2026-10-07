h = {a: 1, b: 2}
g = h
m = {"k" => "s"}
g.merge!(m)
t = 0
h.each { |_k, v| t += v }
p t
