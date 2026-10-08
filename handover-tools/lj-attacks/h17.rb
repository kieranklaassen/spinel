module Lib
  module Tag
    def tag = "tag"
  end
  module Loud
    include Tag
    def tag = super.upcase
  end
end
class Post
  include Lib::Loud
end
module Lib
  class Note
    include Loud
    def tag = "<" + super + ">"
  end
end
p Post.new.tag, Lib::Note.new.tag
