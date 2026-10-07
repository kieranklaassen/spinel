h = {a: 1, b: 2}
h[1] = 2
c = Hash[h]
c[:n] = 5
p h.to_a
p c.equal?(h)
