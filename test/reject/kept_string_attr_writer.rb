# A String variable an attribute writer keeps, then mutated in place through
# the variable: what the object holds would follow it only until the String
# grows. Refused, not silently left behind.
class Box
  attr_accessor :s
end
s = +"s"
b = Box.new
b.s = s
s << "x"
puts b.s
