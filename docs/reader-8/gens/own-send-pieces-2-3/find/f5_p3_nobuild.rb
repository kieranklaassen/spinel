class Mailer
  def send(msg, flags) = "#{msg}:#{flags}"
end
class A
  def table(k) = { k => "v", 9 => "w" }
end
class B
  def table(k) = { k => "x" }
end
[A.new, B.new].each do |x|
  t = x.send(:table, 1)
  p t[1]
end
