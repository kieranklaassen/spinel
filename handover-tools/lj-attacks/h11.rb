module Tag
  def tag = "tag"
end
module Loud
  include Tag
  def tag = super.upcase
end
class Base
  include Loud
end
class Mid < Base
  def tag = "mid"
end
class Leaf < Mid
  def tag = "leaf(" + super + ")"
end
class Side < Base
  def tag = "side(" + super + ")"
end
p Base.new.tag, Mid.new.tag, Leaf.new.tag, Side.new.tag
