module Net
  class Error < StandardError; end
end
module Disk
  class Error < StandardError; end
end
class Plain < StandardError; end
class Net::Error
  def self.q(e) = e.is_a?(Error)
end
Q = ->(e) { Net::Error.q(e) }
row = []
[Net::Error, Disk::Error, Plain].each do |k|
  begin
    raise k, "x"
  rescue => e
    row << (Q.call(e) rescue :ne)
  end
end
p row
