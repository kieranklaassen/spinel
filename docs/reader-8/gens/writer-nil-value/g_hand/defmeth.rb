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
class D
  define_method(:v=) { |x| @v = x; 3 }
  define_method(:v) { @v }
end
d = D.new
p(d.v = nilf)
p d.v
