module Net
  class Error < StandardError; end
end
module Disk
  class Error < StandardError; end
end
class Plain < StandardError; end
module Outer
  module Net
    class Error < StandardError; end
  end
  class Client
    def q(e) = e.is_a?(Net::Error)
  end
end
Q = ->(e) { [Outer::Client.new.q(e), Outer::Client.new.q(Outer::Net::Error.new("o"))] }
row = []
[Net::Error, Disk::Error, Plain].each do |k|
  begin
    raise k, "x"
  rescue => e
    row << (Q.call(e) rescue :ne)
  end
end
p row
