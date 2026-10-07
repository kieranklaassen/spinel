h = {a: 1, b: 2, c: 7}
h.each_key { |k| h.delete(k) }
p h.to_a
