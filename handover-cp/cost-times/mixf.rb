row = [7.5, 3.5, "s", 1]
a = row[0]
b = row[1]
i = 0
x = row[0]
while i < 500000
  x = a + b
  x = a - b
  x = a * b
  x = a / b
  x = a % b
  i += 1
end
p x
