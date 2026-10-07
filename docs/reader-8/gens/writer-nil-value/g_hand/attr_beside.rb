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
class A2
  attr_writer :x
  attr_reader :x, :y
  def y=(q)
    self.x = q
    @y = q
  end
end
a = A2.new
p(a.y = nilf)
p a.x
p a.y
p(a.x = nilf)
