module Net
  class Error < StandardError; end
  def self.mine?(e) = e.is_a?(Error)
end
module Disk
  class Error < StandardError; end
  def self.mine?(e) = e.is_a?(Error)
end
class Plain < StandardError; end
Error = Plain
def top?(e) = e.is_a?(Error)
[Net::Error, Disk::Error, Plain].each do |k|
  begin
    raise k, "x"
  rescue => e
    p [top?(e), Net.mine?(e), Disk.mine?(e), e.is_a?(Net::Error), e.is_a?(Disk::Error)]
  end
end
