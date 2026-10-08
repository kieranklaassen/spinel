module Tag
  def tag(n) = "tag#{n}"
end
module Loud
  include Tag
  def tag(n) = [1, 2].map { |e| super(e + n) }.join("+").upcase
end
class Post
  include Loud
end
p Post.new.tag(10)
