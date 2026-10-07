# A method that keeps its `...` (its `super(...)` reaches a parent that
# yields) has one parameter for each key any of its sites passes. A site
# that leaves a key out passes none: the parent's keyword takes its default
# there, not the nil the forwarder's parameter was bound to.
class Base
  def opt(a, k: 7) = yield([a, k])
  def two(a, k: 7, j: 8) = yield([a, k, j])
  def chain(a, k: 7, j: k + 1) = yield([a, k, j])
  def text(a, k: "d") = yield([a, k])
  def only(k: 7) = yield([k])
  def far(a, k: 7, j: 8) = yield([a, k, j])
end
class Kept < Base
  def opt(...) = super(...)
  def two(...) = super(...)
  def chain(...) = super(...)
  def text(...) = super(...)
  def only(...) = super(...)
end
k = Kept.new
p k.opt(5, k: 2) { |x| x }
p k.opt(5) { |x| x }
p k.two(5, k: 2) { |x| x }
p k.two(5, j: 3) { |x| x }
p k.two(5) { |x| x }
p k.two(5, j: 3, k: 2) { |x| x }
p k.chain(5, k: 2) { |x| x }
p k.chain(5) { |x| x }
p k.text(5, k: "s") { |x| x }
p k.text(5) { |x| x }
p k.only(k: 2) { |x| x }
p k.only { |x| x }

# a forwarder between the two hands the gap on
class Mid < Base
  def far(...) = super(...)
end
class Far < Mid
  def far(...) = [super(...), 1]
end
p Far.new.far(5, k: 2) { |x| x }
p Far.new.far(5, j: 3) { |x| x }
p Far.new.far(5) { |x| x }
