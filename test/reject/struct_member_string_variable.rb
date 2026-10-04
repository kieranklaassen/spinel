# A member changed in place through its reader is a shared String, and a
# String variable stored in it would be copied: refused, not compiled with
# the append lost to the caller's String.
S = Struct.new(:x)
s = "q".dup
c = S.new(s)
c.x << "z"
p c.x, s
