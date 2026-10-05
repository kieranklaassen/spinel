# The same through a method's own parameter: handed to a writer that keeps
# it, then mutated in place. Refused.
class Box
  attr_accessor :s
end
def fill(b, s)
  b.s = s
  s << "x"
end
b = Box.new
t = +"s"
fill(b, t)
p b.s, t
