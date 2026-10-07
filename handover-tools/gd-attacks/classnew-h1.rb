module Net
  Error = Class.new(StandardError)
  module Inner
    Error = Class.new(StandardError)
    def self.t(e) = [e.is_a?(Error), e.instance_of?(Error), e.is_a?(Net::Error)]
  end
  def self.t(e) = [e.is_a?(Error), e.is_a?(Inner::Error)]
end
[Net::Error, Net::Inner::Error].each do |k|
  begin
    raise k, "x"
  rescue => e
    p Net::Inner.t(e), Net.t(e)
  end
end
