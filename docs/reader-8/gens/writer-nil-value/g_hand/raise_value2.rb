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
def boom(f)
  raise IOError, "io" if f
  nil
end
a = K.new
a.v = 3
x = begin
  (a.v = boom(true))
rescue IOError
  :io
end
p x
p a.v
p(a.v = boom(false))
