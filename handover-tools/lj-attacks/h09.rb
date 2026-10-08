module Tag
  def tag = "tag"
end
module Loud
  include Tag
  def tag = super.upcase
end
module Util
  module_function
  def twice(s) = s * 2
end
class Post
  include Loud
  def tag = Util.twice(super)
end
p Post.new.tag
