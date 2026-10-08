Error = Class.new(StandardError)
module Net
  class Error < StandardError
    def self.t(e) = e.is_a?(Error)
  end
end
begin
  raise Net::Error, "x"
rescue => e
  p Net::Error.t(e)
  p e.is_a?(Error)
end
