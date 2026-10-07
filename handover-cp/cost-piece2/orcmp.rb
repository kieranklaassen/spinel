class Box
  attr_accessor :v, :w
  def initialize(v) = (@v = v; @w = nil)
end
Box.new("q").w = "z"
b = Box.new(6)
b.w = 7
i = 0
while i < 2_000_000
  b.v |= (5 <=> b.w)
  i += 1
end
p b.v
