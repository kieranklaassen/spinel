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
S = Struct.new(:a, keyword_init: true) do
  def w=(x)
    self.a = x
  end
end
s = S.new(a: 1)
s.w = nilf
p s.a
