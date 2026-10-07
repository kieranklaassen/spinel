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
class Lg
  def initialize(i)
    @n = "n#{i}"
  end
  def v=(x)
    $acc << @n
    @v = x
  end
end
$acc = []
def mknil(s)
  $tmp = s + "?"
  nil
end
200.times do |i|
  Lg.new(i).v = mknil("s#{i}" * 3)
end
p $acc.size
p $acc.last
p $acc.join.length
