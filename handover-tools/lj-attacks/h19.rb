module Tag
  def tag = "tag"
end
module Loud
  include Tag
  def tag = super.upcase
end
module Other
  def tag = super + "!"
end
class Post
  include Loud
end
class Post
  include Other
end
p Post.new.tag
