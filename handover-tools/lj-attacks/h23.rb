module Tag
  def tag = defined?(super) ? super + "+tag" : "tag"
end
module Loud
  include Tag
  def tag = defined?(super) ? super.upcase : "none"
end
class Base
  def tag = "base"
end
class Post < Base
  include Loud
end
class Note
  include Loud
end
p Post.new.tag, Note.new.tag
