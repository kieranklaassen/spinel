module Net
  class Error < StandardError; end
  def self.mine?(e) = e.is_a?(Error)
end
module Disk
  class Error < StandardError; end
  def self.mine?(e) = e.is_a?(Error)
end
class Plain < StandardError; end
class Net::Late
  def q(e) = (e.is_a?(Error) rescue :name_error)
end
begin
  raise Net::Error, "x"
rescue => e
  p Net::Late.new.q(e)
end
