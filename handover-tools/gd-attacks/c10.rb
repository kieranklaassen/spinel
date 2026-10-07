module Net
  class Error < StandardError; end
end
module Disk
  class Error < StandardError; end
end
class Plain < StandardError; end
module Wrap
  module Net
    class Error < StandardError; end
  end
  def self.q(e) = e.is_a?(Net::Error)
end
Q = ->(e) { Wrap.q(e) }
row = []
[Net::Error, Disk::Error, Plain].each do |k|
  begin
    raise k, "x"
  rescue => e
    row << (Q.call(e) rescue :ne)
  end
end
p row
