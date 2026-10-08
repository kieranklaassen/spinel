module Tag
  def tag = "tag"
end
module Loud
  include Tag
  def tag = super.upcase
end
module Wrap
  include Loud
end
class Base
  def tag = "base"
end
class Post < Base
  include Wrap
  def tag = "<" + super + ">"
end
p Post.new.tag
