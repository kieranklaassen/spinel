class Vec
  def initialize(n) = @n = n
  def *(o) = @n * o
end
row = [Vec.new(2), 3, "s"]
a = row[0]
b = row[1]
i = 0
x = row[1]
while i < 300000
  x = a * b
  i += 1
end
p x
