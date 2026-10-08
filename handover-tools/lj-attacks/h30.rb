module Tag
  def tag = "tag"
  def size = 1
end
module Loud
  include Tag
  def tag = super.upcase
  def size = super + 1
end
module Louder
  include Loud
  def tag = super + "!"
  def size = super * 10
end
class Post
  include Louder
  def size = super + 5
end
p Post.new.tag, Post.new.size
