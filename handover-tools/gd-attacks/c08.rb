module Net
  class Error < StandardError; end
end
module Disk
  class Error < StandardError; end
end
class Plain < StandardError; end
module Mixin
  def q(e) = e.is_a?(Error)
end
module Net
  class Client
    include Mixin
  end
end
Q = ->(e) { Net::Client.new.q(e) }
row = []
[Net::Error, Disk::Error, Plain].each do |k|
  begin
    raise k, "x"
  rescue => e
    row << (Q.call(e) rescue :ne)
  end
end
p row
