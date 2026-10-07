row = ["ab", 3, "cd", [1, 2], [3]]
a = row[0]
b = row[1]
c = row[2]
d = row[3]
e = row[4]
i = 0
n = 0
while i < 200000
  x = a + c
  y = a * b
  z = d + e
  w = d - e
  n += 1
  i += 1
end
p n
