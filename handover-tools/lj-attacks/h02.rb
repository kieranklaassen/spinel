module A
  def tag = "a"
end
module B
  def tag = "b(" + super + ")"
end
module L
  include A
  include B
  def tag = "l(" + super + ")"
end
class Post
  include L
end
class Note
  include L
  def tag = "n(" + super + ")"
end
p Post.new.tag, Note.new.tag
