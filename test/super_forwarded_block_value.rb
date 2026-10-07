# A parent `initialize` that hands its block on to another method, in a
# program that builds the class only through subclasses whose
# `initialize` reaches it by `super`: the value of the forwarding call is
# what the block answers. `Square.new(3) { |n| n * n }.area` was nil.
class Shape
  attr_reader :area, :tags
  def initialize(side, &blk)
    @area = measure(side, &blk)
    @tags = [label(&blk), "shape"]
  end
  def measure(side) = yield(side)
  def label = "#{yield(1)}x"
end
class Square < Shape
  def initialize(side, &blk) = super(side, &blk)
end
class Tile < Square
  def initialize(...) = super(...)
end
s = Square.new(3) { |n| n * n }
p s.area, s.tags
t = Tile.new(4) { |n| n + 1 }
p t.area, t.tags

# the value in an Array literal and as a condition, through a bare super
class Gauge
  attr_reader :pair, :mark
  def initialize(a, &)
    @pair = [read(a, &), 1]
    @mark = read(a, &) ? :yes : :no
  end
  def read(a) = yield(a)
end
class Dial < Gauge
  def initialize(a) = super
end
d = Dial.new(2) { |x| x * 3 }
p d.pair, d.mark

# two subclasses whose blocks answer different types
class Text < Gauge
  def initialize(a, &b) = super(a, &b)
end
p Text.new(2) { |x| "s#{x}" }.pair

# a method of an included module the class reaches by super
module Scale
  def weigh(a, &b)
    @w = tare(a, &b)
  end
  def tare(a) = yield(a)
end
class Pan
  include Scale
  attr_reader :w
  def weigh(...) = super(...)
end
pan = Pan.new
p pan.weigh(2) { |x| x + 40 }
p pan.w

# a class that is also built directly keeps its answer
class Cell
  attr_reader :v
  def initialize(a, &b)
    @v = fill(a, &b)
  end
  def fill(a) = yield(a)
end
class Wide < Cell
  def initialize(a, &b) = super(a, &b)
end
p Cell.new(5) { |x| x + 1 }.v
p Wide.new(2) { |x| x * 3 }.v
