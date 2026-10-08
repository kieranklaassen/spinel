# A class held by value (scalar ivars written only in initialize, no
# subclass) calls super into an included module's method.
module Scaled
  def area(k) = k * 2
  def to_s = "scaled"
end
class Tile
  include Scaled
  def initialize(w); @w = w; end
  def area(k) = super(k + @w) + 1
  def to_s = "tile " + super
end

# between two modules' methods, the class defining neither
module Doubled
  def area(k) = super * 2
end
class Slab
  include Scaled
  include Doubled
  def initialize(w); @w = w; end
  def width = @w
end

# the super inside a block
class Grid
  include Scaled
  def initialize(n); @n = n; end
  def area(k) = [1, 2].map { |e| super(e + k) + @n }.sum
end

t = Tile.new(3)
p t.area(1)
puts t.to_s
s = Slab.new(2)
p s.area(5), s.width
p Grid.new(1).area(10)
