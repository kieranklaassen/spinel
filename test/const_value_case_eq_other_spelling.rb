# One class under two spellings: the second body binds the constant anew,
# and the read in the first body is of the new value.
LIM = 1..5
class Object
  LIM = 7..9
end
p(LIM === 3)

module A
  class X
    TOP = 1..5
    def t = TOP === 3
  end
end
class A::X
  TOP = 7..9
end
p A::X.new.t

class Z
  NAME = "abc"
  def t = NAME === "abc"
end
Y = Z
class Y
  NAME = "xyz"
end
p Z.new.t
