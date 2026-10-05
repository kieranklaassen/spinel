# A Struct member left nil by `new` and given a String by its setter is a
# boxed slot; the String read from it is appended to: refused by name.
S = Struct.new(:x)
c = S.new
c.x = +"q"
c.x << "z"
p c.x
