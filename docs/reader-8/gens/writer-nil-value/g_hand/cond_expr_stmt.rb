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
a = K.new
a.v = nilf if true
a.v = bump unless false
(a.v = nilf) while false
x = 0
x += 1 until (a.v = bump).nil?
p x
