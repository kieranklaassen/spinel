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
def get(o)
  puts "get"
  o
end
def nila(o)
  puts "nila"
  nil
end
a = K.new
get(a).v = nila(get(a))
p a.v
