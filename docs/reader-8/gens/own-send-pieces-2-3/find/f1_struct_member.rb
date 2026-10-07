class Mailer
  def send(msg, flags) = "#{msg}:#{flags}"
end
Job = Struct.new(:send, :at) do
  def run = "ran"
end
m = [:run, :to_s][ARGV.size]
puts Job.new(1, 2).send(m)
