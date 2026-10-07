row = [7, 3, "s", 1.5]
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
  x = a << b
  i += 1
end
p x
