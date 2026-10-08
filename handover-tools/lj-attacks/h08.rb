module Tag
  def tag = "tag"
end
module Loud
  include Tag
  def tag = super.upcase
end
module Loud
  alias label tag
end
class Post
  include Loud
end
p Post.new.label, Post.new.tag
