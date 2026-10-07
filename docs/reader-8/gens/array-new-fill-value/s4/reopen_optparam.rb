class String
  def fillwith(o = self + "!") = Array.new(2, o)
end
s = "abc"
t = "def"
u = "xyz"
rows = []
24.times do
  rows << ((s + t).fillwith)
  z = s + u
  z = u + s
end
bad = rows.count { |r| r != rows[0] }
p rows.size
p bad
p rows[0]
