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
k = K.new
x = 5
x = (k.v = nilf) if $c == 0
p x
x = 6
p x + 1
y = "s"
y = (k.v = bump)
p y
