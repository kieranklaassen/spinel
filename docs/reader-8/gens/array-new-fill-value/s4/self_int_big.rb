class Integer
  def tw = Array.new(2, self)
end
s = "abc"
t = "def"
u = "xyz"
rows = []
24.times do
  rows << ((2**70 + rows.size * 0).tw)
  z = s + u
  z = u + s
end
bad = rows.count { |r| r != rows[0] }
p rows.size
p bad
p rows[0]
