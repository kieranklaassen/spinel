class Vec
  def initialize(n) = @n = n
  def *(o) = Vec.new(@n * o)
  def n = @n
end
row = ["ab", 3, 1.5]
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
p (Vec.new(2) * 3).n
