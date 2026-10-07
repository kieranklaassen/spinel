class String
  def tw(n) = Array.new(n, self)
end
s = "abc"
t = "def"
u = "xyz"
rows = []
24.times do
  rows << ((s + t).tw(2))
  z = s + u
  z = u + s
end
bad = rows.count { |r| r != rows[0] }
p rows.size
p bad
p rows[0]
