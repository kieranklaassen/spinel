# A block that ends in `b.call(v)` on the block parameter of the method it is
# written in. The call is a splice of the block handed in, and where that
# block ends in a call with a block of its own the splice, written as a
# statement, had no value: the C did not build.
def pass(v) = yield(v)
def g(x, &b) = pass(x) { |w| b.call(w) }
r = g(1) { |v| pass(v) { |w| w * 3 } }
p r
p g(2) { |v| pass(v) { |w| pass(w) { |u| u + 40 } } }

# the block handed in ends in the same form, one method further up
def h(x, &b) = g(x) { |v| pass(v) { |w| b.call(w) } }
p h(1) { |v| v * 2 }

# a chain of such methods over a yielding far end
def far(x) = yield(x + 1)
def k3(x, &b) = far(x) { |v| pass(v) { |w| b.call(w) } }
def k2(x, &b) = k3(x) { |v| pass(v) { |w| b.call(w) } }
def k1(x, &b) = k2(x) { |v| pass(v) { |w| b.call(w) } }
p k1(1) { |v| v * 2 }

# instance methods
class Wrap
  def pass(v) = yield(v)
  def g(x, &b) = pass(x) { |w| b.call(w) }
  def h(x) = g(x) { |v| pass(v) { |w| w + 1 } }
end
p Wrap.new.h(1)

# right before: Strings, with `b.yield`, `b.()` and a statement ahead of
# the tail
def spass(v) = yield(v)
def sg(x, &b) = spass(x) { |w| t = w + "-"; b.yield(t) }
def sh(x, &b) = sg(x) { |v| spass(v) { |w| b.(w) } }
p sh("a") { |v| v + "!" }
p sg("b") { |v| spass(v) { |w| w * 2 } }

# and right before: the block handed in ends in a plain expression, and one
# method's two call sites answer nil and an Integer
def qpass(v) = yield(v)
def q(x, &b) = qpass(x) { |w| b.call(w) }
q(1) { |v| puts v }
y = q(2) { |v| puts v; v + 1 }
p y
