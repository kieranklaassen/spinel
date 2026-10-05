# A String variable an attribute writer keeps, mutated in place through the
# variable, and then read back through the object: the read would miss the
# mutation. Refused.
class Box
  attr_accessor :s
end
s = +"s"
b = Box.new
b.s = s
s << "x"
puts b.s
