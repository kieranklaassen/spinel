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
class U
  def _v=(x)
    @v = x
    1
  end
  def V=(x)
    @v = x
    2
  end
  def v = @v
end
u = U.new
p(u._v = nilf)
p(u.V = bump)
p u.v
