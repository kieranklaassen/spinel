module Net
  class Error < StandardError; end
end
module Disk
  class Error < StandardError; end
end
class Plain < StandardError; end
module Net
  class Base
    def initialize; @n = 1; end
    def q(e) = [@n, e.is_a?(Error)]
  end
end
class Sub < Net::Base
  def initialize; super; @m = 2; end
end
Q = ->(e) { Sub.new.q(e) }
row = []
[Net::Error, Disk::Error, Plain].each do |k|
  begin
    raise k, "x"
  rescue => e
    row << (Q.call(e) rescue :ne)
  end
end
p row
