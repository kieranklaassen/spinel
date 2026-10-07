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
[1].each { |i| p(k.v = nilf) }
r = [1, 2].select { |i| k.v = nilf }
p r
r2 = [1, 2].reject { |i| k.v = bump }
p r2
p [3, 4].map { |i| k.w = nilf }.compact
p([1, 2].all? { |i| k.v = nilf })
p([1, 2].find { |i| k.v = nilf })
p [1, 2].count { |i| k.v = nilf }
