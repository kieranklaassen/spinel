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
    @n = x.size
  end
  def n = @n
end
a = C2.new
a.n = [1, 2]
p a.n
a.n = nilf
p a.n
