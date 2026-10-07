class Own
  def zend(msg, flags) = [msg, flags]
  def val(k) = [k, 1]
end
class Plain
  def val(k) = [k, 2]
end
x = ARGV.size == 0 ? Own.new : Plain.new
r = x.is_a?(Own) ? x.zend(:val, 1) : x.val(1)
p r.first
