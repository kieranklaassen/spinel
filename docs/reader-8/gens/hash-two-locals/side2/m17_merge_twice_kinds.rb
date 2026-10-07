h = {}
m = {:a => 1}
h.merge!(m)
g = h
m = {"b" => "x"}
h.merge!(m)
p g.to_a
