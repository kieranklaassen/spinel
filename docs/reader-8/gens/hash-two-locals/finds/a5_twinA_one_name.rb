h = {"a" => "x", "b" => "yy"}
m = {1 => "x"}
h.merge!(m) if ARGV.size > 5
p h.invert.invert == h
