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
def f4(k, f)
  return 5 if f
  k.v = nilf
end
k = K.new
p f4(k, true)
p f4(k, false)
p f4(k, false).nil?
