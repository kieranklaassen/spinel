h = {1 => 1, 2 => 2, 3 => 7}
m = {"k" => 1}
h.merge!(m) if ARGV.size > 5
p h.sort_by { |k, _v| k.to_s }
