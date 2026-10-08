module Tag
  def tag = "tag"
end
module Loud
  include Tag
  def tag = super.upcase
end
o = Object.new
o.extend(Loud)
p o.tag
