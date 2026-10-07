# A program's own is_a? answers for itself: a constant's class is not read
# into the call.
class Proxy
  def initialize(o) = @o = o
  def is_a?(k) = false
end
K = Proxy
p Proxy.new(1).is_a?(K)
p [Proxy.new(1), 7].map { |v| v.is_a?(K) }
