module Tag
  def tag(a, b = 2, k: 3) = "tag#{a}#{b}#{k}"
end
module Loud
  include Tag
  def tag(a, b = 5, k: 6) = super(a, b + 1, k: k + 1).upcase
end
class Post
  include Loud
end
class Note
  include Loud
  def tag(a, k: 1) = "<" + super(a, k: k) + ">"
end
p Post.new.tag(1), Post.new.tag(1, 2, k: 3), Note.new.tag(7), Note.new.tag(7, k: 8)
