h = {a: 1}
m = {1 => 1}
h.merge!(m) if ARGV.size > 5
c = Hash[h]
c[:n] = 5
p h.to_a
