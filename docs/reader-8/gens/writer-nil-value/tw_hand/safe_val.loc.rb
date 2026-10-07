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
b = $c > 5 ? a : nil
p((t9 = nilf; b&.v = t9))
p((t9 = nilf; a&.v = t9))
p a.v
