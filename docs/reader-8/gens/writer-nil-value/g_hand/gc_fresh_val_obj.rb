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
class Big
  def initialize(i)
    @s = "big" * (i + 1)
  end
end
def mknil(b)
  nil
end
t = 0
300.times do |i|
  k = K.new("k#{i}")
  k.v = mknil(Big.new(i))
  t += 1 if k.v.nil? && k.name == "k#{i}"
end
p t
