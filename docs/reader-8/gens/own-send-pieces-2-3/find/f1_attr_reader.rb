class Mailer
  def send(msg, flags) = "#{msg}:#{flags}"
end
class Job
  attr_reader :send
  def run = "ran"
end
m = [:run, :to_s][ARGV.size]
puts Job.new.send(m)
