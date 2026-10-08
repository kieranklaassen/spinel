module Tag
  def tag = "tag"
end
module Loud
  include Tag
  def tag = super.upcase
end
Pt = Struct.new(:a) do
  include Loud
end
class Qt < Struct.new(:a)
  include Loud
  def tag = super + a.to_s
end
p Pt.new(1).tag, Qt.new(2).tag
