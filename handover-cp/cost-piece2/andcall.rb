class Box
  attr_accessor :v, :n
  def initialize(v)
    @v = v
    @n = 0
  end
  def three
    @n += 1
    3
  end
end
Box.new("q")
b = Box.new(6)
i = 0
while i < 2_000_000
  b.v &= b.three
  i += 1
end
p b.v
