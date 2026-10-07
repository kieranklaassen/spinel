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
  p [r].sum, r << 2
end
