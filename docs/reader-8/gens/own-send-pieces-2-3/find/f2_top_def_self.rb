class Own
  def send(msg, flags = 0) = "own:#{msg}:#{flags}"
  def go(m) = helper(m)
end
def ping = "top#ping"
def helper(m) = self.send(m)
m = [:ping, :to_s][ARGV.size]
puts Own.new.go(m)
