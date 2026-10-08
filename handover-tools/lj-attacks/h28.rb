module Tag
  def tag = "tag"
end
module Loud
  include Tag
  def tag = super.upcase
end
class Fault < StandardError
  include Loud
end
begin
  raise Fault, "x"
rescue => e
  p e.tag, e.message
end
