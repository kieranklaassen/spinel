h = {a: 1}
60.times { |i| h["k#{i}".to_sym] = i }
p h.size
p h.keys.last
