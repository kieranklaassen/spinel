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
def f1(k)
  return k.v = nilf
end
def f2(k)
  k.v = nilf
end
def f3(k) = (k.w = bump)
k = K.new
p f1(k)
p f2(k)
p f3(k)
x = f2(k)
p x.nil?
