class Symbol
  def tw = (x = self; Array.new(2, x))
end
s = "abc"
t = "def"
u = "xyz"
rows = []
24.times do
  rows << ((s + t).to_sym.tw)
  z = s + u
  z = u + s
end
bad = rows.count { |r| r != rows[0] }
p rows.size
p bad
p rows[0]
