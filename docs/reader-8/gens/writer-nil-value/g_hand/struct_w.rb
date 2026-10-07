def nilf
  puts "nilf"
  nil
end
$c = 0
def bump
  $c += 1
  puts "bump"
  nil
end
class K
  def initialize(n = "k")
    @name = n
  end
  def name = @name
  def v=(x)
    @v = x
    42
  end
  def v = @v
  def w=(x)
    @w = x
    "wret"
  end
  def w = @w
end
S = Struct.new(:a, :b) do
  def w=(x)
    self.a = x
    9
  end
end
s = S.new(1, 2)
p(s.w = nilf)
p s.a
s.a = nilf
p s.a
p(s.b = nilf)
p s.b
