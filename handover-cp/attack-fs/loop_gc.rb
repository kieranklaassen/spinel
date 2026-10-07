xs = []
200.times { |i| xs << i }
row = [3.0, "s", 150.0, Rational(7, 1), nil, 199.5]
c = 0
s = []
1000.times do |i|
  n = row[i % 6]
  c += 1 if xs.include?(n)
  r = xs.index(n)
  s << "a#{i}" if r
  c += r if r
end
p c, s.size
