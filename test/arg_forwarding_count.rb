# Through a method that keeps its `...` (its `super(...)` reaches a parent
# that yields), the parent judges the number of arguments as it does at a
# plain call: too few or too many is CRuby's ArgumentError.
class Base
  def two(a, b) = yield([a, b])
  def key(a, k: 7) = yield([a, k])
  def none = yield([])
  def far(a, b) = yield([a, b])
end
class Kept < Base
  def two(...) = super(...)
  def key(...) = super(...)
  def none(...) = super(...)
end
k = Kept.new
def judged
  yield
rescue ArgumentError => e
  puts e.message
end

p k.two(1, 2) { |x| x }
judged { p k.two(1) { |x| x } }
judged { p k.two(1, 2, 3) { |x| x } }
judged { p k.two { |x| x } }

# a keyword is not counted
p k.key(1, k: 2) { |x| x }
judged { p k.key(k: 2) { |x| x } }
judged { p k.key(1, 2) { |x| x } }
judged { p k.key(1, 2, k: 3) { |x| x } }

p k.none { |x| x }
judged { p k.none(1) { |x| x } }

# through two forwarders, and with the block passed as a value
class Mid < Base
  def far(...) = super(...)
end
class Far < Mid
  def far(...) = super(...)
end
pr = proc { |x| x }
p Far.new.far(3, 4, &pr)
judged { p Far.new.far(3, &pr) }

# two forwarders that each name a parameter of their own take it from the
# forwarded arguments: the parent is handed none
class Low
  def lead(k: 7) = yield([k])
end
class Middle < Low
  def lead(x, ...) = super(...)
end
class Top < Middle
  def lead(x, ...) = super(...)
end
p Top.new.lead(1, 2) { |v| v }
