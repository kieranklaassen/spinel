module Net
  class Error < StandardError; end
end
module Disk
  class Error < StandardError; end
end
class Plain < StandardError; end
module Net
  class Timeout < Error; end
  def self.q(e) = [e.is_a?(Timeout), e.is_a?(Error)]
end
Q = ->(e) { (Net.q(Net::Timeout.new("t")) + Net.q(e)) }
row = []
[Net::Error, Disk::Error, Plain].each do |k|
  begin
    raise k, "x"
  rescue => e
    row << (Q.call(e) rescue :ne)
  end
end
p row
