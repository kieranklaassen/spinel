module Net
  class Error < StandardError; end
  module Inner
    Error = Class.new(StandardError)
    def self.t(e) = e.is_a?(Error)
  end
end
begin
  raise Net::Error, "x"
rescue => e
  p Net::Inner.t(e)
end
