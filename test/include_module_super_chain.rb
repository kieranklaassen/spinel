# A module that includes another holds the `super` between their methods.
# Whatever includes that module takes the methods with it.
module Tag
  def tag = "tag"
  def level(n) = n
end
module Loud
  include Tag
  def tag = super.upcase
  def level(n) = super(n + 1) * 10
end

# no method of its own
class Post
  include Loud
end

# its own method reaches the module's, and that one the inner module's
class Note
  include Loud
  def tag = "<" + super + ">"
end

# through a superclass
class Base
  include Loud
end
class Memo < Base
  def tag = "[" + super + "]"
end

# a module in between that defines nothing
module Wrap
  include Loud
end
class Page
  include Wrap
end

# an earlier include stands behind both
module Plain
  def tag = "plain"
end
module Inner
  def tag = super + "?"
end
module Outer
  include Inner
  def tag = "(" + super + ")"
end
class Card
  include Plain
  include Outer
end

p Post.new.tag
p Post.new.level(1)
p Note.new.tag
p Memo.new.tag
p Base.new.tag
p Page.new.tag
p Card.new.tag
