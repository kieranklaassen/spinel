# A block written at a `super` yields again to the block `new` was given.
# The parent hands its block on to another method, so the written block is
# run from two calls deep and its own `yield` still finds the caller's.
class Shape
  attr_reader :area
  def initialize(side, &blk)
    @area = measure(side, &blk)
  end
  def measure(side) = yield(side)
end
class Square < Shape
  def initialize(side) = super(side) { |n| yield n }
end
p Square.new(3) { |n| n * n }.area

# the parent wraps the block in one of its own
class Frame
  attr_reader :w
  def initialize(a)
    @w = pass(a) { |z| yield z }
  end
  def pass(a) = yield(a)
end
class Inner < Frame
  def initialize(a) = super(a) { |q| yield(q) + 1 }
end
p Inner.new(2) { |x| x * 3 }.w

# three links, and a link between them that is a bare super
class Outer < Inner
  def initialize(a) = super(a) { |g| yield g + 10 }
end
class Outermost < Outer
  def initialize(a) = super
end
p Outer.new(2) { |x| x * 3 }.w
p Outermost.new(5) { |x| x * 3 }.w

# `new` inside a method that yields, and an anonymous `&` in the parent
class Row
  attr_reader :cells
  def initialize(a, &)
    @cells = [fill(a, &), 1]
  end
  def fill(a) = yield(a)
end
class Line < Row
  def initialize(a) = super(a) { |c| yield c }
end
def build(a) = Square.new(a) { |y| yield y }.area
p build(4) { |x| x + 100 }
p Line.new(2) { |x| x * 3 }.cells

# blocks that answer a String, a Symbol and nil
p Square.new(2) { |n| "s#{n}" }.area
p Line.new(2) { |x| :k }.cells
p Line.new(2) { |x| nil }.cells
