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
class N
  def initialize
    puts "new"
  end
  def v=(x)
    puts "set #{x.inspect}"
  end
end
N.new.v = nilf
p(N.new.v = nilf)
