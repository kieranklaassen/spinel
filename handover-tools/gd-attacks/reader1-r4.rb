module Net
  class Error < StandardError; end
  module Inner
    Error = Class.new(Net::Error)
    def self.t(e) = e.instance_of?(Error)
  end
end
begin
  raise Net::Error, "x"
rescue => e
  p Net::Inner.t(e)
end
