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
h = {a: (puts "1"; 1), b: (k.v = nilf), c: (puts "3"; 3)}
p h[:a]
p h[:b]
p h.size
