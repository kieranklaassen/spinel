module Net
  class Error < StandardError; end
  Fault = Class.new(Error)
  module Inner
    Fault = Class.new(StandardError)
    def self.t(e) = [e.is_a?(Fault), e.is_a?(Error), e.is_a?(Net::Fault)]
  end
end
module Disk
  class Error < StandardError; end
  def self.t(e) = [e.is_a?(Error), e.is_a?(Net::Error)]
end
[Net::Error, Net::Fault, Net::Inner::Fault, Disk::Error].each do |k|
  begin
    raise k, "x"
  rescue => e
    p Net::Inner.t(e), Disk.t(e)
  end
end
