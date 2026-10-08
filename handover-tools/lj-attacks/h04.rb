module Tag
  def tag = "tag"
end
module Loud
  include Tag
  def tag = super.upcase
end
class Post
  include Loud
  def tag(twice = false) = twice ? super() + super() : super()
end
p Post.new.tag, Post.new.tag(true)
