row = ["ab", 2.5, 1]
a = row[0]
b = row[1]
i = 0
n = 0
while i < 300000
  x = a * b
  n += 1
  i += 1
end
p n
