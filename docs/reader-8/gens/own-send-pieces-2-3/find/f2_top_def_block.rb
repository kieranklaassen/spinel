class Own
  def send(msg, flags = 0) = "own:#{msg}:#{flags}"
  def go(m) = helper(m)
end
def ping = "top#ping"
def helper(m) = [1].map { |i| send(m) }.first
m = [:ping, :to_s][ARGV.size]
puts Own.new.go(m)
