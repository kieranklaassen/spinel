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
    puts "B2"
    @x = q
    2
  end
end
def pick(f) = f ? B2.new : B1.new
o = pick(true)
p(o.x = nilf)
p o.x
o2 = pick(false)
p(o2.x = nilf)
[B1.new, B2.new].each { |z| p(z.x = nilf) }
