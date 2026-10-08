module Tag
  def tag = "tag"
end
module Loud
  include Tag
  def tag = super.upcase
end
class A
  include Loud
end
class B
  include Loud
  def tag = "b:" + super
end
class C
  include Loud
  def tag = "c"
end
p A.new.tag, B.new.tag, C.new.tag
