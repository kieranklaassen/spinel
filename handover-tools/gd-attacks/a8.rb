module Net
  class Error < StandardError; end
  def self.mine?(e) = e.is_a?(Error)
  class Client
    def q(e) = e.kind_of?(Error)
    def i(e) = e.instance_of?(Error)
  end
end
class Plain < StandardError; end
[Net::Error, Plain].each do |k|
  begin
    raise k, "x"
  rescue => e
    p [Net.mine?(e), Net::Client.new.q(e), Net::Client.new.i(e), e.is_a?(Net::Error)]
  end
end
