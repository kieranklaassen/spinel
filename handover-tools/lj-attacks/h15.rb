module Tag
  def <=>(o) = rank <=> o.rank
end
module Loud
  include Comparable
  include Tag
  def <=>(o) = -super(o)
end
class Post
  include Loud
  attr_reader :rank
  def initialize(r); @rank = r; end
end
p Post.new(1) < Post.new(2), Post.new(3) < Post.new(2), [Post.new(1), Post.new(3), Post.new(2)].max.rank
