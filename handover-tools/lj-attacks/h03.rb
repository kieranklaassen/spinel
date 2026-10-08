module T1
  def tag = "t1"
end
module L1
  include T1
  def tag = "l1(" + super + ")"
end
module T2
  def tag = "t2(" + super + ")"
end
module L2
  include T2
  def tag = "l2(" + super + ")"
end
class Post
  include L1
  include L2
end
class Note
  include L2
  include L1
  def tag = "n(" + super + ")"
end
p Post.new.tag, Note.new.tag
