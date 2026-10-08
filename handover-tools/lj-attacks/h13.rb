module Tag
  def initialize(x); @t = "t#{x}"; end
end
module Loud
  include Tag
  def initialize(x); super(x + 1); @l = "l#{x}"; end
  def show = [@t, @l]
end
class Post
  include Loud
end
class Note
  include Loud
  def initialize(x); super(x * 10); @n = x; end
  def show = super + [@n]
end
p Post.new(1).show, Note.new(2).show
