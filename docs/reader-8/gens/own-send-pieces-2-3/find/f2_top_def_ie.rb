class Own
  def send(msg, flags = 0) = "own:#{msg}:#{flags}"
end
def ping = "top#ping"
def helper(m) = send(m)
m = [:ping, :to_s][ARGV.size]
puts Own.new.instance_eval { helper(m) }
