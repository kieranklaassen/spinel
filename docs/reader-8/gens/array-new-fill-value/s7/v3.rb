s = "abc"
t = "def"
u = "xyz"
k = 3
rows = []
24.times do |i|
  rows << Array.new((s + u).size - 4, (s + t rescue u))
  z = s + u
  z = [u + s, z]
end
puts rows.size
puts rows.count { |r| r != ["abcdef", "abcdef"] }
