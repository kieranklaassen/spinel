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
class K
  class << self
    def cv=(x)
      @cv = x
      5
    end
    def cv = @cv
  end
end
y = (K.cv = nilf)
p y
p K.cv
