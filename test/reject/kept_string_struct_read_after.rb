# A String variable a Struct's `new` keeps as a member, mutated in place
# through the variable, and the member read afterwards. Refused.
Pair = Struct.new(:x, :y)
s = +"s"
pr = Pair.new(s, 1)
s.insert(0, ">")
p pr.x
