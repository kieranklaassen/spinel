s = "abc"
t = "def"
u = "xyz"
k = 3
rows = []
24.times do |i|
  rows << Array.new((s + u).size - 4, (case k when 3 then k += 0; s + t else u end))
  z = s + u
  z = [u + s, z]
end
puts rows.size
puts rows.count { |r| r != ["abcdef", "abcdef"] }
