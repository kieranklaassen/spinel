module Tag
  private
  def tag = "tag"
end
module Loud
  include Tag
  def shout = tag
  private
  def tag = super.upcase
end
class Post
  include Loud
end
p Post.new.shout
p((Post.new.tag rescue "private"))
