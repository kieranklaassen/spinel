class String
  def each_twice
    yield self
  end
end
s = "abc"
t = "def"
u = "xyz"
rows = []
24.times do
  rows << ((s + t).each_twice { |o| Array.new(2, o) })
  z = s + u
  z = u + s
end
bad = rows.count { |r| r != rows[0] }
p rows.size
p bad
p rows[0]
