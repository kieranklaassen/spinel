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

# One nested class, named bare from the bodies around the call.
module Lib
  class Fault < StandardError; end
  def self.mine?(e) = e.is_a?(Fault)
  class Client
    def mine?(e) = e.kind_of?(Fault)
  end
end

begin
  raise Lib::Fault, "odd"
rescue => e
  p [Lib.mine?(e), Lib::Client.new.mine?(e), e.instance_of?(Lib::Fault)]
end

# A path's first name is the module Ruby finds from the body: the Net an
# included module holds, not the program's own.
module Mixin
  module Net
    class Error < StandardError; end
  end
end
module Wrap
  include Mixin
  def self.mine?(e) = e.is_a?(Net::Error)
end

begin
  raise Net::Error, "down"
rescue => e
  p [Wrap.mine?(e), e.is_a?(Net::Error), e.is_a?(Mixin::Net::Error)]
end
