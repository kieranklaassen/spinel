module Net
  class Error < StandardError; end
  def self.mine?(e) = e.is_a?(Error)
end
module Disk
  class Error < StandardError; end
  def self.mine?(e) = e.is_a?(Error)
end
class Plain < StandardError; end
module Other
  Error = Plain
  def self.q(e) = e.is_a?(Error)
  def self.r(e) = e.is_a?(Other::Error)
end
[Net::Error, Disk::Error, Plain].each do |k|
  begin
    raise k, "x"
  rescue => e
    p [Other.q(e), Other.r(e), e.is_a?(Other::Error), Net.mine?(e)]
  end
end
