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
class H2
  def initialize
    self.z = nilf
    @q = (self.z = bump)
  end
  def z=(x)
    @z = x
    7
  end
  def z = @z
  def q = @q
end
h = H2.new
p h.z
p h.q
