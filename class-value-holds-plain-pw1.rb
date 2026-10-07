class Img
  def initialize(x, y = "c" * 2, z = "d" * 2)
    @v = [x, y, z]
  end
  def ok?(i) = @v[0] == i && @v[1] == "cc" && @v[2] == "dd"
end
class Other
  def initialize(x) = (@x = x)
  def ok?(i) = @x == i
end
kl = [Img, Other][0]
bad = 0
keep = []
i = 0
while i < 300_000
  o = kl.new(i)
  keep << [o, i] if i % 7 == 0
  bad += 1 unless o.ok?(i)
  i += 1
end
bad2 = 0
keep.each { |o, n| bad2 += 1 unless o.ok?(n) }
p bad, bad2, keep.size
