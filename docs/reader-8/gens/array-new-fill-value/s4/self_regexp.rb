class Regexp
  def tw = Array.new(2, self)
end
s = "abc"
t = "def"
u = "xyz"
rows = []
24.times do
  rows << (Regexp.new(s + t).tw.map(&:source))
  z = s + u
  z = u + s
end
bad = rows.count { |r| r != rows[0] }
p rows.size
p bad
p rows[0]
