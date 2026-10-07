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
class C2
  def n=(x)
    @n = x
  end
  def n = @n
end
a = C2.new
a.n = 5
y = (a.n = nilf)
p y
z = (a.n = 6)
p z
p [a.n = nilf, a.n = 7]
