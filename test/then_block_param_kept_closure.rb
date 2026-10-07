# The parameter of a `then` or `tap` block is a new variable at each run of
# the block: a block that captures it and is kept by a method reads the
# value of its own run, whatever ran after.

def keep(&b) = b

# a block kept by a method that takes it as `&b`, made in each run of a then
fs = [7, 8, 9].map { |e| x = e; x.then { |v| keep { v + 1 } } }
p fs.map(&:call)

# two levels: the outer parameter and the inner one
gs = []
3.times do |i|
  i.then { |v| v.then { |w| gs << keep { v + w } } }
end
p gs.map(&:call)

# a Float receiver, inside a method
def halves
  hs = []
  i = 0
  while i < 3
    hs << (i + 0.5).then { |v| keep { v * 2 } }
    i += 1
  end
  hs.map(&:call)
end
p halves

# a String receiver: each closure keeps its own
ss = ["a", "b", "c"].map { |s| t = s; t.then { |v| keep { v + "!" } } }
p ss.map(&:call)

# tap, its value used: the block kept in it reads that run's receiver
ks = []
ys = [[1], [2, 3]].map { |a| b = a; b.tap { |v| ks << keep { v.sum } } }
p ks.map(&:call), ys

# yield_self, and a block kept by an object's method
class Reg
  def initialize = @hs = []
  def on(&b) = @hs << b
  def run = @hs.map(&:call)
end
r = Reg.new
[7, 8, 9].each { |e| x = e; x.yield_self { |v| r.on { v + 1 } } }
p r.run

# the closure still sees a later write of its own run's parameter
ws = [1, 2].map { |e| x = e; x.then { |v| k = keep { v }; v += 10; k } }
p ws.map(&:call)

# a `next` out of one run leaves the others their own
ns = [0, 1, 2, 3].map { |e| x = e; x.then { |v| next keep { -1 } if v == 2; keep { v } } }
p ns.map(&:call)

# inside the block of a method that yields, two levels deep
def thrice
  yield 1
  yield 2
  yield 3
end
ts = []
thrice { |n| x = n * 2; x.then { |v| ts << keep { v }; v.then { |w| ts << keep { v + w } } } }
p ts.map(&:call)

# values of several kinds through one block
ms = [1, "a", :s, nil, 2.5].map { |e| y = e; y.then { |o| keep { o.inspect } } }
p ms.map(&:call)
