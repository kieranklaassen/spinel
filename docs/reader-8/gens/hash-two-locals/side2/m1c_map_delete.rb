h = {a: 1, b: 2, c: 7}
p h.map { |k, v| h.delete(k); v }
p h.to_a
