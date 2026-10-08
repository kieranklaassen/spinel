module Tag
  def tag = "tag#{@n}"
end
module Loud
  include Tag
  def tag = super.upcase + @s
end
class Post
  include Loud
  def initialize; @n = 4; @s = "!"; end
  def bump; @n += 1; self; end
end
p Post.new.tag, Post.new.bump.tag
