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
class K
  def z=(x)
    r = (self.v = x)
    p r
    @z = r
  end
  def z = @z
end
a = K.new
p(a.z = nilf)
p a.z
p a.v
