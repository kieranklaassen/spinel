# A constant made by Class.new is the class a bare name means where it is in
# scope, not the class of that name in an outer module or in another one.
module Net
  class Error < StandardError; end
  module Inner
    Error = Class.new(StandardError)
    def self.own?(e) = e.is_a?(Error)
    def self.same?(e) = e.instance_of?(Error)
  end
end
module Disk
  class Fault < StandardError; end
end
Fault = Class.new(StandardError)

begin
  raise Net::Error, "down"
rescue => e
  p [Net::Inner.own?(e), Net::Inner.same?(e), e.is_a?(Net::Error)]
end
begin
  raise Disk::Fault, "full"
rescue => e
  p [e.is_a?(Fault), e.kind_of?(Fault), e.is_a?(Disk::Fault)]
end
