# `instance_variable_set` reaches an attribute's slot by a name the program
# gives as a String. An attribute `o.x ||= v` writes keeps its boxed slot in
# a program that calls it, so nil stored that way is read back as nil.

class Box
  attr_accessor :x, :y
end

def clear(o) = o.instance_variable_set("@y", nil)

r = Box.new
r.x ||= +"ab"
r.x << "z"
r.instance_variable_set("@x", nil)
p r.x

r.y ||= "a#{1}b"
r.y.upcase!
clear(r)
p r.y
