module Tag
  def tag = "tag"
end
module Loud
  include Tag
  def tag = super.upcase
end
class Post
  include Loud
end
p Post.ancestors.take(3), Post.include?(Tag), Post.new.is_a?(Tag), Post.instance_method(:tag).owner
