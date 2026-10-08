module Tag
  def to_s = "tag"
  def ==(o) = o == 1
end
module Loud
  include Tag
  def to_s = super.upcase
  def ==(o) = super(o) || o == 2
end
class Post
  include Loud
end
x = Post.new
puts x.to_s, "#{x}"
p x == 1, x == 2, x == 3
