class Box
  attr_accessor :v
  def initialize(v) = @v = v
end

Box.new("q")
b = Box.new(6)
a = [7, 5, 3, 6]
i = 0
while i < 2_000_000
  b.v |= a[1]
  i += 1
end
p b.v
