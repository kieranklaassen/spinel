# A Struct member whose String is changed in place through its reader is a
# shared String, and the String `new` is given is not one: the member would
# hold a copy. It did not compile to C that builds; it is refused by name.
S = Struct.new(:x)
c = S.new("q".dup)
c.x << "z"
p c.x
