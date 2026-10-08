xs = [1, 2, 3, 4, 5, 6, 7, 8]
row = [5.0, 3.0, :pad]
i = 0
c = 0
while i < 300000
  n = row[i & 1]
  r = xs.index(n); c += 1 if r
  i += 1
end
p c
