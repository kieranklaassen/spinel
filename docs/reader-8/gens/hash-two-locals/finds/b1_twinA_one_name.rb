h = {1 => 1, 2 => 2}
m = {"k" => 1}
h.merge!(m) if ARGV.size > 5
h.each { |k, _v| h.delete(k) }
p h.to_a
