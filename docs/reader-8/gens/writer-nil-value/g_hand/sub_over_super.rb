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
class B1
  def x=(q)
    @x = q
    1
  end
  def x = @x
end
class B2 < B1
  def x=(q)
    super(q)
    p(super)
    2
  end
end
o = B2.new
p(o.x = nilf)
p o.x
