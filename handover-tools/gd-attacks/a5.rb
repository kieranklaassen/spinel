module Net
  class Error < StandardError; end
  def self.mine?(e) = e.is_a?(Error)
end
module Disk
  class Error < StandardError; end
  def self.mine?(e) = e.is_a?(Error)
end
class Plain < StandardError; end
module Net
  class Client
    Error = Plain
    def q(e) = e.is_a?(Error)
  end
  class Server
    def q(e) = e.is_a?(Error)
    def b(e) = [1].map { e.is_a?(Error) }
  end
end
[Net::Error, Disk::Error, Plain].each do |k|
  begin
    raise k, "x"
  rescue => e
    p [Net::Client.new.q(e), Net::Server.new.q(e), Net::Server.new.b(e)]
  end
end
