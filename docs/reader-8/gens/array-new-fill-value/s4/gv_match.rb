s = "abc"
t = "def"
u = "xyz"
rows = []
24.times do
  (s + t) =~ /b(cd)e/
  rows << Array.new(2, $~).map { |m| m[1] }
  rows << Array.new(2, $1)
  rows << Array.new(2, $&)
  z = s + u
  z = u + s
end
p rows.size
p rows.uniq
