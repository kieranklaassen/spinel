module Net
  class Error < StandardError; end
  def self.mine?(e) = e.is_a?(Error)
end
module Disk
  class Error < StandardError; end
  def self.mine?(e) = e.is_a?(Error)
end
class Plain < StandardError; end
Net.const_set(:Extra, 1)
begin
  raise Net::Error, "x"
rescue => e
  p Net.mine?(e), e.is_a?(Net::Error)
end
