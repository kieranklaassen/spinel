class Proc
  def tw = (x = self; Array.new(2, x))
end
s = "abc"
t = "def"
u = "xyz"
rows = []
24.times do
  rows << ((proc { s + t }).tw.map(&:call))
  z = s + u
  z = u + s
end
bad = rows.count { |r| r != rows[0] }
p rows.size
p bad
p rows[0]
