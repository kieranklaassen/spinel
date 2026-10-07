class Integer
  def fillwith(o) = Array.new(self, o)
end
s = "abc"
t = "def"
u = "xyz"
rows = []
24.times do
  rows << (2.fillwith(s + t))
  z = s + u
  z = u + s
end
bad = rows.count { |r| r != rows[0] }
p rows.size
p bad
p rows[0]
