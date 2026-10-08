xs = [1, 2, 3, 4, 5, 6, 7, 8]
row = [2**70, 2**71, :pad]
i = 0
c = 0
while i < 300000
  n = row[i & 1]
  c += 1 if xs.include?(n)
  i += 1
end
p c
