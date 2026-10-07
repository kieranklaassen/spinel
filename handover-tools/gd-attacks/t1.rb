# Two modules each name an exception class Error. is_a?, kind_of? and
# instance_of? on a rescued exception ask for the class the path names, by
# the name the exception carries ("Net::Error"), in a path and as the bare
# name inside its module.
module Net
  class Error < StandardError; end
  class Timeout < Error; end
  def self.mine?(e) = e.is_a?(Error)
end

module Disk
  class Error < StandardError; end
  def self.mine?(e) = e.is_a?(Error)
end

def kinds(e)
  [e.is_a?(Net::Error), e.kind_of?(Disk::Error), e.instance_of?(Net::Error),
   Net.mine?(e), Disk.mine?(e), e.is_a?(StandardError)]
end

begin
  raise Net::Error, "down"
rescue => e
  p kinds(e)
end

begin
  raise Net::Timeout, "slow"
rescue => e
  p kinds(e)
end

begin
  raise Disk::Error, "full"
rescue => e
  p kinds(e)
end

begin
  raise ArgumentError, "bad"
rescue => e
  p kinds(e)
end
