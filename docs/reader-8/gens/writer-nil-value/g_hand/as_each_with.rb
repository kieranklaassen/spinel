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
r = [1, 2].each_with_object([]) { |i, acc| acc << (k.v = nilf) }
p r
p [1, 2].inject(0) { |s, i| (k.v = nilf); s + i }
