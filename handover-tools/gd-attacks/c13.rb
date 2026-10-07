module Net
  class Error < StandardError; end
end
module Disk
  class Error < StandardError; end
end
class Plain < StandardError; end
module Net
  class Client
    def q(e) = e.is_a?(Disk::Error)
    def r(e) = e.is_a?(::Net::Error)
  end
end
Q = ->(e) { c = Net::Client.new; [c.q(e), c.r(e)] }
row = []
[Net::Error, Disk::Error, Plain].each do |k|
  begin
    raise k, "x"
  rescue => e
    row << (Q.call(e) rescue :ne)
  end
end
p row
