xs = [1, 2, 3, 4, 5, 6, 7, 8]
row = [:k, :pad]
n = row[0]
i = 0
c = 0
while i < 300000
  c += 1 if xs.include?(n)
  i += 1
end
p c
