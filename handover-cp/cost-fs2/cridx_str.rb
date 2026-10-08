xs = [1, 2, 3, 4, 5, 6, 7, 8]
row = ["x", "y", :pad]
i = 0
c = 0
while i < 300000
  n = row[i & 1]
  c += 1 if xs.rindex(n)
  i += 1
end
p c
