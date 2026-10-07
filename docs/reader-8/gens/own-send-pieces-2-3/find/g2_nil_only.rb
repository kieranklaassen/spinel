class Own
  def send(msg, flags = 0) = "own:#{msg}:#{flags}"
end
def pick(i) = i == 0 ? Own.new : nil
x = pick(ARGV.size + 1)
p x.send(:to_s)
p x.send(:nil?)
