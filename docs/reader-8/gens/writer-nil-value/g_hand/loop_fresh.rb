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
$keep = []
def nal(i)
  $keep << ("x" * (i + 20))
  nil
end
t = 0
i = 0
while i < 200
  k = K.new("f#{i}")
  r = (k.v = nal(i))
  t += 1 if r.nil? && k.v.nil?
  i += 1
end
p t
p $keep.size
