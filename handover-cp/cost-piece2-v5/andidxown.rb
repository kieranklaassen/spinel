class Box
  attr_accessor :v
  def initialize(v) = @v = v
end
class Vec
  attr_reader :x
  def initialize(x) = @x = x
  def +(o) = Vec.new(@x + o.x)
  def [](k) = @x + k
end
p((Vec.new(1) + Vec.new(2))[3])
Box.new("q")
b = Box.new(6)
a = [7, 5, 3, 6]
i = 0
while i < 2_000_000
  b.v &= a[i & 3]
  i += 1
end
p b.v
