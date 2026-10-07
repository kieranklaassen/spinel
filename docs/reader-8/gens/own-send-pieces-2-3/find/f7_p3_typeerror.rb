class Own
  def send(msg, flags) = [msg, flags]
  def val(k) = [k, 1]
end
class Plain
  def val(k) = [k, 2]
end
x = ARGV.size == 0 ? Own.new : Plain.new
r = x.send(:val, 1)
p r.first
