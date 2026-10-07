row = [2**70, 3, "s"]
a = row[0]
b = row[1]
i = 0
x = row[0]
while i < 300000
  x = a * b
  i += 1
end
p x
