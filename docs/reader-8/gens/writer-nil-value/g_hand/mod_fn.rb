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
module Cfg
  def self.lvl=(x)
    @lvl = x
    1
  end
  def self.lvl = @lvl
end
p(Cfg.lvl = nilf)
p Cfg.lvl
Cfg.lvl = 3
p Cfg.lvl
y = (Cfg.lvl = bump)
p y
