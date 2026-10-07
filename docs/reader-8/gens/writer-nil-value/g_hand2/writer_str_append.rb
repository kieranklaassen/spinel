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
class VW
  def v=(x)
    @v = x
  end
  def v = @v
end
o = VW.new
s = +"ab"
o.v = s
s << "c"
p o.v
o.v = nilf
p o.v
p s
