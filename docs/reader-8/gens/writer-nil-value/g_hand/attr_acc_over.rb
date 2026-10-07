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
class A3
  attr_accessor :x
  def x=(q)
    puts "over"
    @x = q
  end
end
a = A3.new
p(a.x = nilf)
p a.x
a.x = 5
p a.x
