# Data#with stores a String in a member that holds a shared String: here
# `D.new(x: s, ...)` gave it `s`, which the program appends to. The new
# Data's member would hold a copy of "c", so the `with` is refused, with
# or without the append through `e.x` below. `D.new(x: s.dup, ...)` builds.
D = Data.define(:x, :n)
s = +"a"
s << "b"
d = D.new(x: s, n: 1)
e = d.with(x: "c".dup)
e.x << "z"
p e.x, d.x
