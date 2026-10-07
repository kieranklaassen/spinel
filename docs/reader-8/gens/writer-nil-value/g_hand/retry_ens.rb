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
a = K.new
n = 0
begin
  n += 1
  a.v = (raise "x" if n < 2; bump)
rescue
  retry
ensure
  puts "ens"
end
p n
p a.v
