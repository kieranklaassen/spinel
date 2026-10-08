module Net
  class Error < StandardError; end
end
module Disk
  class Error < StandardError; end
end
class Plain < StandardError; end
module Outer
  module Web
    class Error < StandardError; end
  end
  class Client
    def q(e) = e.is_a?(Web::Error)
    def r(e) = e.instance_of?(Outer::Web::Error)
  end
end
Q = ->(e) { c = Outer::Client.new; x = Outer::Web::Error.new("o"); [c.q(e), c.q(x), c.r(e), c.r(x)] }
row = []
[Net::Error, Disk::Error, Plain].each do |k|
  begin
    raise k, "x"
  rescue => e
    row << (Q.call(e) rescue :ne)
  end
end
p row
