# `k.new` on a Class value runs the defaults of the class it builds and of
# no other. A default's hoisted statement was written ahead of the switch
# over the classes, where it ran whichever class the value held.
$log = []
def note(s) = ($log << s; s)
def logged = (r = $log.dup; $log.clear; r)

class Img
  def initialize(d = note("img") * 2)
    @d = d
  end
  def v = @d
end
class Other
  def initialize(d = note("other") * 2)
    @d = d
  end
  def v = @d
end
class Keyed
  def initialize(k: note("keyed") * 2)
    @d = k
  end
  def v = @d
end

# no argument, the class read out of an Array and picked by a condition
3.times { |i| p [Img, Other, Keyed][i].new.v, logged }
k = ARGV.empty? ? Other : Img
p k.new.v, logged

# an argument given, a later default that iterates
class Row
  def initialize(a, e = [1, 2].map { |x| note("row"); x * a })
    @e = e
  end
  def v = @e
end
class Col
  def initialize(a, e = [3].map { |x| note("col"); x * a })
    @e = e
  end
  def v = @e
end
2.times { |i| p [Row, Col][i].new(2).v, logged }
k = ARGV.empty? ? Col : Row
p k.new(3).v, logged

# a class with its own `new`
class Made
  def self.new(d = [1, 2].map { |x| note("made"); x * 2 }) = d
end
class Built
  def self.new(d = [3].map { |x| note("built"); x * 2 }) = d
end
2.times { |i| p [Made, Built][i].new, logged }
k = ARGV.empty? ? Built : Made
p k.new, logged
p k.new([0]), logged
