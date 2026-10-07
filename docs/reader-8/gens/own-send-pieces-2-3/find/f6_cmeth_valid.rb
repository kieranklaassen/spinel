class Own
  def __send__(msg, flags = 0) = "own:#{msg}:#{flags}"
end
class Plain
  def self.ping = "Plain.ping"
  def self.go(m) = __send__(m)
end
m = [:ping, :secret][ARGV.size]
p Plain.go(m)
