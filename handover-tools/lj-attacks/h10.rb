module Tag
  def tag = "tag"
end
module Loud
  include Tag
  def tag = super.upcase
end
class Post
  extend Loud
end
p Post.tag
