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
x = Post.new
p x.send(:tag), x.public_send(:tag), x.method(:tag).call, x.respond_to?(:tag)
