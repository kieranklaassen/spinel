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
  Other = Disk
  def self.q(e) = e.is_a?(Other::Error)
end
module App
  Net = ::Disk
  def self.q(e) = e.is_a?(Net::Error)
end
[Net::Error, Disk::Error].each do |k|
  begin
    raise k, "x"
  rescue => e
    p [Net.q(e), App.q(e)]
  end
end
