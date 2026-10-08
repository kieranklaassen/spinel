module Tag
  def tag = "tag"
end
module Loud
  include Tag
  def tag = super.upcase
end
class Post
  include Loud
  def tag = super + super
end
class Note < Post
  def tag = "n" + super
end
p Post.new.tag, Note.new.tag
