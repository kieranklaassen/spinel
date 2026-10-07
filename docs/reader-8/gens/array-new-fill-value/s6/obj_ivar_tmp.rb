class Box
  def initialize(m) = @m = m
  def tw = Array.new(2, @m)
end
s = "abc"
t = "def"
u = "xyz"
rows = []
24.times do
  rows << (Box.new(s + t).tw)
  z = s + u
  z = u + s
end
bad = rows.count { |r| r != rows[0] }
p rows.size
p bad
p rows[0]
