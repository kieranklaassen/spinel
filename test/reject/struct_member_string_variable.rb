# The same for a String a variable still holds: the append through the
# member's reader would not reach `s`, so the store is refused.
S = Struct.new(:x, :n)
s = +"s"
u = s
u << "a"
c = S.new(s, 1)
c.x << "z"
p c.x, s
