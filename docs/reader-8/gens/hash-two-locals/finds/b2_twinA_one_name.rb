h = {a: 1, b: 2}
m = {"k" => "s"}
h.merge!(m)
t = 0
h.each { |_k, v| t += v }
p t
