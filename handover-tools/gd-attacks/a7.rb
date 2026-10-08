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
  def self.rooted(e) = (e.is_a?(::Error) rescue :name_error)
  def self.pathed(e) = e.is_a?(Net::Error)
  def self.other(e) = e.is_a?(Disk::Error)
end
[Net::Error, Disk::Error].each do |k|
  begin
    raise k, "x"
  rescue => e
    p [Net.rooted(e), Net.pathed(e), Net.other(e)]
  end
end
