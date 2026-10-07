class Own
  def zend(msg, flags = 0) = "own:#{msg}:#{flags}"
  def go(m) = helper(m)
end
def ping = "top#ping"
def helper(m) = send(m)
m = [:ping, :to_s][ARGV.size]
puts Own.new.go(m)
