class Mailer
  def send(msg, flags) = "#{msg}:#{flags}"
end
class Job
  attr_accessor :send
  def initialize = @send = "queued"
  def run = "ran"
end
j = Job.new
puts j.send
m = [:run, :to_s][ARGV.size]
puts j.send(m)
