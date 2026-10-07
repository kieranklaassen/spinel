class String
  def tw0 = Array.new(2, self)
  alias tw tw0
end
s = "abc"
t = "def"
u = "xyz"
rows = []
24.times do
  rows << ((s + t).tw)
  z = s + u
  z = u + s
end
bad = rows.count { |r| r != rows[0] }
p rows.size
p bad
p rows[0]
