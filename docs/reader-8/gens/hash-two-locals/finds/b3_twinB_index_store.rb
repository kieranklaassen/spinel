h = {1 => 1, 2 => 2, 3 => 7}
g = h
g["k"] = 1 if ARGV.size > 5
p h.sort_by { |k, _v| k.to_s }
