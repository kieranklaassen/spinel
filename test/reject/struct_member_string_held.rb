# The String another object's reader answers is that object's own: stored
# in a member changed in place it would be copied, so it is refused.
class Owner
  attr_reader :name
  def initialize(n) = @name = n
end
D = Data.define(:x)
o = Owner.new("q".dup)
c = D.new(x: o.name)
c.x << "z"
p c.x, o.name
