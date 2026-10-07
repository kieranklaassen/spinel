class Vec
  def initialize(n) = @n = n
  def *(o) = Vec.new(@n * o)
  def n = @n
end
row = [3, 5, "s"]
a = row[0]
b = row[1]
i = 0
x = row[0]
while i < 1000000
  x = a * b
  i += 1
end
p x
p (Vec.new(2) * 3).n
