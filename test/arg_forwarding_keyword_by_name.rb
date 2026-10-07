# Through a method that keeps its `...` (its `super(...)` reaches a parent
# that yields), a keyword of the parent binds by name: in whatever order the
# site wrote the keys, and to its own default where no site passes it.
class Base
  def pair(a, k:, j:) = yield([a, k, j])
  def opt(a, k: 7) = yield([a, k])
  def two(a, k: 7, j: 8) = yield([a, k, j])
  def text(a, k: "d") = yield([a, k])
  def none(a, k: nil) = yield([a, k])
  def chain(a, k: 7, j: k + 1) = yield([a, k, j])
  def only(k: 7) = yield([k])
end
class Kept < Base
  def pair(...) = super(...)
  def opt(...) = super(...)
  def two(...) = super(...)
  def text(...) = super(...)
  def none(...) = super(...)
  def chain(...) = super(...)
  def only(...) = super(...)
end
k = Kept.new
p k.pair(5, j: 3, k: 2) { |x| x }
p k.opt(5) { |x| x }
p k.two(5, j: 3) { |x| x }
p k.text(5) { |x| x }
p k.none(5) { |x| x }
p k.chain(5, k: 2) { |x| x }
p k.only { |x| x }

# the keys in the order the parent declares them, as before
p k.pair(6, k: 2, j: 3) { |x| x }

# two levels, and the super inside an Array
class Deep < Base
  def two(...) = super(...)
end
class Deeper < Deep
  def two(...) = [super(...), 1]
end
p Deeper.new.two(5, j: 3) { |x| x }
