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
puts "a" unless ((t9 = nilf; k.v = t9))
puts "b" if !((t9 = nilf; k.v = t9))
puts "c" if ((t9 = nilf; k.v = t9)).nil?
puts(((t9 = nilf; k.v = t9)).to_s.empty?)
