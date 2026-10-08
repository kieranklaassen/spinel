module Net
  class Error < StandardError; end
end
module Disk
  class Error < StandardError; end
end
class Plain < StandardError; end
module Mixin
  module Net
    class Error < StandardError; end
  end
end
include Mixin
Q = ->(e) { [e.is_a?(Net::Error), Mixin::Net::Error.new("m").is_a?(Net::Error)] }
row = []
[Net::Error, Disk::Error, Plain].each do |k|
  begin
    raise k, "x"
  rescue => e
    row << (Q.call(e) rescue :ne)
  end
end
p row
