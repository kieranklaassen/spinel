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
p((k.v = nilf).to_s)
p((k.v = nilf).to_a)
p((k.v = nilf).inspect)
p((k.v = nilf).to_i)
p((k.v = nilf).to_h.size)
p((k.v = nilf).class)
p((k.v = nilf) & true)
p((k.v = nilf) | true)
