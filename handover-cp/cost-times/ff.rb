row = [1.5, 2.5, "s"]
a = row[0]
b = row[1]
i = 0
x = row[0]
while i < 1000000
  x = a * b
  i += 1
end
p x
