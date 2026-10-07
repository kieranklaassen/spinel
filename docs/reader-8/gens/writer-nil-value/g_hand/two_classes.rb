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
class A1
  def v=(x)
    @v = x
    :a
  end
  def v = @v
end
class A2
  def v=(x)
    @v = x.to_s
    :b
  end
  def v = @v
end
[A1.new, A2.new].each { |o| p(o.v = nilf); p o.v }
a = A1.new
b = A2.new
p(a.v = nilf)
p(b.v = bump)
p b.v
