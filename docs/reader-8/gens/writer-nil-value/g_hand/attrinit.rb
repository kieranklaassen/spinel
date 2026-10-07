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
class H3
  attr_reader :z
  def z=(x)
    @z = x
  end
  def initialize
    @z = 5
  end
end
h = H3.new
p h.z
h.z = nilf
p h.z
h.z = 6
p h.z
