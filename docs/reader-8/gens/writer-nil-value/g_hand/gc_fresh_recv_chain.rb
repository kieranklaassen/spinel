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
class Hd
  def initialize(i)
    @o = K.new("o#{i}")
  end
  def o = @o
end
def mknil(s)
  nil
end
t = 0
300.times do |i|
  h = Hd.new(i)
  r = (h.o.v = mknil("s#{i}" * 3))
  t += 1 if r.nil? && h.o.v.nil? && h.o.name == "o#{i}"
end
p t
