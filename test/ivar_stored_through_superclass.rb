# An instance variable a superclass's method stores, read from an instance
# of the subclass. The method takes the instance as its own struct type; the
# C compiler must still see the store when the read is through the
# subclass's.

class Shape
  attr_reader :kind
  def initialize(sides)
    label = sides
    label = "many" if sides > 1000
    @kind = label ? :polygon : :none
  end
end

class Square < Shape
  def initialize(sides) = super
end

class Tile < Square
  def initialize(sides) = super
end

class Scale
  attr_reader :factor
  def initialize(n)
    f = n
    f = 1.5 if n > 1000
    @factor = f ? 2.5 : 3.5
  end
end

class Zoom < Scale
  def initialize(n) = super(n)
end

class Pair
  attr_reader :left, :right
  def initialize(n)
    @left = n
    r = n
    r = "s" if n > 1000
    @right = r ? 1 : 2
  end
end

class Twin < Pair
  def tag = :twin
end

Point = Struct.new(:x, :y) do
  def shift(a)
    q = a
    q = "s" if a > 1000
    self.x = q ? 5 : 6
    self
  end
end

class Pixel < Point
  def tag = :pixel
end

square = Square.new(4)
p square.kind
tile = Tile.new(4)
p tile.kind
zoom = Zoom.new(2)
p zoom.factor
twin = Twin.new(7)
p twin.right
p twin.left
pixel = Pixel.new(1, 2)
pixel.shift(2)
p pixel.x
