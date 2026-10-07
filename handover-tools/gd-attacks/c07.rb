module Net
  class Error < StandardError; end
end
module Disk
  class Error < StandardError; end
end
class Plain < StandardError; end
module Net
  module Deep
    class Probe
      def q(e) = e.instance_of?(Error)
    end
  end
end
Q = ->(e) { Net::Deep::Probe.new.q(e) }
row = []
[Net::Error, Disk::Error, Plain].each do |k|
  begin
    raise k, "x"
  rescue => e
    row << (Q.call(e) rescue :ne)
  end
end
p row
