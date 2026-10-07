# An object of a small immutable class written as a Hash literal's key or
# value. The class was laid out by value, and each literal boxed a copy of
# the object: two literals holding the same object held two. Each part has
# a class of its own, since one use that needs a heap object gives the
# whole class one.
class Tag
  attr_reader :n
  def initialize(n) = @n = n
end

# as a key
tag = Tag.new(1)
p({ tag => :a } == { tag => :a })
h = { tag => 1 }
g = { tag => 2 }
p h.merge(g).size
p [{ tag => 1 }, { tag => 1 }].uniq.size
p h.key?(g.keys[0])
other = Tag.new(1)
p({ tag => :a } == { other => :a })
p tag.n + other.n

# as a value
class Coin
  attr_reader :cents
  def initialize(cents) = @cents = cents
end
coin = Coin.new(5)
p({ a: coin } == { a: coin })
v = { a: coin, b: coin }
p v[:a].equal?(v[:b]), v.values.uniq.size
p({ coin: } == { coin: })

# keywords and a Hash argument without braces store it the same way
class Mark
  def initialize(x, y) = (@x = x; @y = y)
  def sum = @x + @y
end
def opts(**o) = o
def one(h) = h
mark = Mark.new(1.5, 2.5)
p opts(a: mark) == opts(a: mark)
p one(mark => 1) == one(mark => 1)
p mark.sum
