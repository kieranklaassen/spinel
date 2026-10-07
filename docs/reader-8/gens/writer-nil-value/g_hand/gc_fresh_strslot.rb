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
class Sv
  def v=(x)
    @v = x
  end
  def v = @v
end
def mknil(s)
  $tmp = s + "?"
  nil
end
t = 0
200.times do |i|
  o = Sv.new
  o.v = "str#{i}"
  r = (o.v = mknil("s#{i}"))
  t += 1 if r.nil? && o.v.nil?
  o.v = "again#{i}"
  t += o.v.length
end
p t
