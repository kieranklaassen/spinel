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
class H
  def initialize(o)
    @o = o
  end
  def o = @o
end
h = H.new(K.new)
h2 = H.new(nil)
p(h.o&.v = nil)
p(h2.o&.v = nil)
p h.o.v
