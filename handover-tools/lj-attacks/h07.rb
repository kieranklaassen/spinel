module Tag
  attr_reader :name
end
module Loud
  include Tag
  def name = super.to_s.upcase
end
class Post
  include Loud
  def initialize(n); @name = n; end
end
p Post.new("x").name
