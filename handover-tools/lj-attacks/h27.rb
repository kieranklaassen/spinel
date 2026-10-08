module Tag
  def tag = (super rescue "none") + ":tag"
end
module Loud
  include Tag
  def tag = super.upcase
end
class Post
  include Loud
end
p Post.new.tag
