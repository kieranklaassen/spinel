# A class of the program's own may be named as one of the runtime's C types:
# Array#sum's accumulator and the socket address carrier.
class SumState
  def initialize(total) = @total = total
  def add(n) = SumState.new(@total + n)
  def total = @total
end
p SumState.new(1).add(2).total, [1, 2, 3].sum, [0.1, 0.2].sum

module Net
  class Addrinfo
    attr_reader :host
    def initialize(host) = @host = host
    def to_s = "addr #{@host}"
  end
end
a = Net::Addrinfo.new("h")
puts a, a.host

class SumState
  def to_s = "sum #{@total}"
end
puts SumState.new(4)
p SumState.new(4).class, a.class, a.is_a?(Net::Addrinfo)

class StateError < StandardError; end
class Addrinfo < StateError
  def hint = "no address"
end
begin
  raise Addrinfo, "x"
rescue Addrinfo => e
  puts "got #{e.message} #{e.class} #{e.hint}"
end
