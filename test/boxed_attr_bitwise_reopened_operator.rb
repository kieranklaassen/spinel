# `o.v ^= x` reads the slot before x runs, also where x looks like a plain
# read and is the program's own method: a reopened Float's `+` and `<`, a
# reopened Array's `[]`, each writing the slot it is the operand of.
class Float
  def +(other)
    $box.v = 9
    1
  end

  def <(other)
    $box.v = true
    true
  end
end

class Array
  def [](index)
    $box.v = 9
    7
  end
end

class Box
  attr_accessor :v
  def initialize(v) = @v = v

  def flip(list, i)
    self.v ^= list[i]
    v
  end
end

Box.new("s")
o = Box.new(6)
$box = o
o.v ^= (1.5 + 2)
p o.v

o.v = 6
list = [10, 1, 30]
i = 1
o.v ^= list[i]
p o.v

o.v = 6
p o.flip(list, i)

o.v = 6
o.v |= list[i]
p o.v

o.v = nil
o.v &= (1.5 < 2)
p o.v
