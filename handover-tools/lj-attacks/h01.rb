module Tag
  def tag = "tag"
end
module Loud
  def tag = super.upcase
end
module Loud
  include Tag
end
class Post
  include Loud
end
p Post.new.tag
