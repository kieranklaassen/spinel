module Net
  class Error < StandardError; end
end
module Disk
  class Error < StandardError; end
  Wrapped = Struct.new(:error)
  Pair = Data.define(:left)
  def self.t(e) = [e.is_a?(Error), Wrapped.new(e).error.is_a?(Error), Pair.new(left: e).left.is_a?(Net::Error)]
end
[Net::Error, Disk::Error].each do |k|
  begin
    raise k, "x"
  rescue => e
    p Disk.t(e)
  end
end
