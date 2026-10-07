class Plain
  def self.ping = "Plain.ping"
  def self.go(m) = send(m)
end
m = [:ping, :to_s][ARGV.size]
p Plain.go(m)
