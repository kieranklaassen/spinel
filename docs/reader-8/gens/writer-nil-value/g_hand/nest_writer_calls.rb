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
  def both=(x)
    self.v = x
    self.w = (bump; x)
    @r = (self.v = nilf)
    :b
  end
  def r = @r
end
a = K.new
p(a.both = nilf)
p a.v
p a.w
p a.r
