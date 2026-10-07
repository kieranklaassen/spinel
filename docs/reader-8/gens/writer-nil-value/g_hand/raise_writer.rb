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
class R
  def v=(x)
    raise ArgumentError, "nope" if x.nil?
    @v = x
  end
end
r = R.new
begin
  r.v = nilf
rescue ArgumentError => e
  puts "rescued #{e.message}"
end
r.v = nilf
puts "unreached"
