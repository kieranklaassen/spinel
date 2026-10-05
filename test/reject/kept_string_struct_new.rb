# A String variable a Struct's `new` keeps as a member, then mutated in place
# through the variable. Refused.
Pair = Struct.new(:x, :y)
s = +"s"
pr = Pair.new(s, 1)
s.insert(0, ">")
p pr.x
