# A Struct member that holds a String or an Integer is a boxed slot, and the
# String read from it is appended to: refused by name, not a C error.
S = Struct.new(:x, :y)
c = S.new(+"q", +"r")
c.x = 1 if ARGV.size == 9
c.x << "z"
p c.to_a
