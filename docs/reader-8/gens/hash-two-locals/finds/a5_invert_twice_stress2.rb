h = {"a" => "x", "b" => "yy"}
g = h
m = {1 => "x"}
g.merge!(m) if ARGV.size > 5
p h.invert.invert == h
