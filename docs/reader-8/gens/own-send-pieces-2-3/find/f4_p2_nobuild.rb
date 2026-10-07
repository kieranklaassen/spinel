class Mailer
  def send(msg, flags) = "#{msg}:#{flags}"
end
class A
  def count(k) = k + 2
end
class B
  def count(k) = k + 3
end
[A.new, B.new].each do |x|
  r = x.send(:count, 1)
  p r.zero?, r.to_s(2), r.between?(1, 5), [r].sum, r.fdiv(2), r & 1, r << 2, r ** 2, -r, r.abs
end
