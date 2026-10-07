h = {"a" => "x", "b" => "yy"}
g = h
g[1] = "x" if ARGV.size > 5
p h.invert.invert == h
