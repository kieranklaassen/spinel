module Net
  class Error < StandardError; end
end
module Disk
  class Error < StandardError; end
end
class Plain < StandardError; end
class Base
  class Error < StandardError; end
end
class Sub < Base
  def q(e) = e.is_a?(Error)
end
Q = ->(e) { [Sub.new.q(e), Sub.new.q(Base::Error.new("b"))] }
row = []
[Net::Error, Disk::Error, Plain].each do |k|
  begin
    raise k, "x"
  rescue => e
    row << (Q.call(e) rescue :ne)
  end
end
p row
