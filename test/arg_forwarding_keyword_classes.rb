# Keywords of different classes through a method that keeps its `...`,
# written at the site in another order than the parent declares them: each
# is typed as it is bound, by name.
class Base
  def two(a, k:, j:) = yield([a, k, j])
  def use(a, k:, j:) = yield([a, k + 1, j + "!"])
  def thr(a, k:, j:, l:) = yield([a, k, j, l.size])
  def self.make(a, k:, j:) = yield([a, k * 2, j.to_s])
end
class Kept < Base
  def two(...) = super(...)
  def use(...) = super(...)
  def thr(...) = super(...)
  def self.make(...) = super(...)
end
k = Kept.new

p k.two(5, j: "s", k: 2) { |x| x }
p k.use(5, j: "t", k: 3) { |x| x }
# an Array beside an Integer
p k.thr(5, l: [1, 2], j: "u", k: 4) { |x| x }
p Kept.make(5, j: :y, k: 1.5) { |x| x }

# through the block as a proc
pr = proc { |x| x }
p k.use(6, j: "v", k: 7, &pr)

# through two forwarders
class Mid < Base
  def far(a, k:, j:) = yield([a, k + 1, j + "!"])
end
class Near < Mid
  def far(...) = super(...)
end
class Far < Near
  def far(...) = super(...)
end
p Far.new.far(7, j: "w", k: 8) { |x| x }

# an initialize that yields
class Shape
  def initialize(a, k:, j:)
    @v = [a, k + 1, j + "!"]
    yield self
  end
  attr_reader :v
end
class Round < Shape
  def initialize(...) = super(...)
end
Round.new(9, j: "z", k: 1) { |o| p o.v }
