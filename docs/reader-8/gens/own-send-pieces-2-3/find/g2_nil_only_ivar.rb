class Own
  def initialize = @tag = "t"
  def send(msg, flags = 0) = "#{@tag}:#{msg}:#{flags}"
end
def pick(i) = i == 0 ? Own.new : nil
x = pick(ARGV.size + 1)
p x.send(:to_s)
