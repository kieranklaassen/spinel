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
class VW
  def v=(x)
    @v = case x
         when nil then :nil
         when Integer then :int
         else :other
         end
  end
  def v = @v
end
o = VW.new
o.v = nilf
p o.v
o.v = 3
p o.v
