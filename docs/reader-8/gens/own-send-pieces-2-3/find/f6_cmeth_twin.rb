class Plain
  def self.ping = "Plain.ping"
  def self.go(m) = __send__(m)
end
m = [:secret, :ping][ARGV.size]
p Plain.go(m)
