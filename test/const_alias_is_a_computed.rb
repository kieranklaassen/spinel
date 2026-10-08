# A method defined under a name no literal spells may be the program's own
# is_a?: a constant's class is not read into the call.
class Proxy
  def initialize(o) = @o = o
  define_method(("is_" + "a?").to_sym) { |k| false }
end
K = Proxy
p Proxy.new(1).is_a?(K)
p [Proxy.new(1), 7].map { |v| v.is_a?(K) }
