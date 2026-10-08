# A method that keeps its `...` (its `super(...)` reaches a parent that
# yields) hands the block to a forward beside the super too, where that
# forward's method yields: `note(...)` runs under the same block.
class Reader
  def each_row(n) = yield(n)
end
class Logged < Reader
  def each_row(...) = [super(...), note(...)]
  def note(n) = block_given? ? yield(n) : -1
end
class Loud < Reader
  def each_row(...) = [super(...), tell(...)]
  def tell(n) = yield(n)
end
p Logged.new.each_row(2) { |x| x * 3 }
p Loud.new.each_row(2) { |x| x * 3 }

# the block's own state is one state across both runs
seen = []
r = Loud.new.each_row(4) do |x|
  seen << x
  x + 1
end
p r, seen

# the forward first, as a statement, and under a receiver
class Tool
  def use(n) = yield(n) + 100
end
class Order < Reader
  def each_row(...) = [tell(...), super(...)]
  def tell(n) = yield(n) + 1
end
class Quiet < Reader
  def each_row(...)
    tell(...)
    super(...)
  end
  def tell(n) = @told = yield(n)
  def told = @told
end
class Lent < Reader
  def each_row(...) = [super(...), self.tell(...), Tool.new.use(...)]
  def tell(n) = yield(n)
end
p Order.new.each_row(2) { |x| x * 3 }
q = Quiet.new
p q.each_row(2) { |x| x * 3 }, q.told
p Lent.new.each_row(2) { |x| x * 3 }

# three classes deep, and through a method that was itself given the block
class Deep < Loud
  def each_row(...) = [super(...), tell(...)]
end
def through(o, &b) = o.each_row(5, &b)
p Deep.new.each_row(2) { |x| x * 3 }
p through(Logged.new) { |x| x - 1 }

# with no block at the site there is none to hand on
class Maybe
  def each_row(n) = block_given? ? yield(n) : -2
end
class Calm < Maybe
  def each_row(...) = [super(...), note(...)]
  def note(n) = block_given? ? yield(n) : -1
end
p Calm.new.each_row(2)
p Calm.new.each_row(2) { |x| x * 3 }

# a method that runs the block and does not read what it answers takes a
# block with any last statement
class Trail
  def walk(n) = yield(n)
end
class Walk < Trail
  def walk(...)
    super(...)
    visit(...)
  end
  def visit(n)
    yield(n)
    n
  end
end
out = []
p Walk.new.walk(2) { |x| out << x while out.size < 3 }
p out

# The forward is left as it was where the block is not known to run right
# under it. Each call below leaves before its forward is reached.

# a block that holds a `break`
class Feed
  def feed(n) = yield(n)
end
class Cut < Feed
  def feed(...) = [super(...), seen(...)]
  def seen(n) = yield(n)
end
p Cut.new.feed(2) { |x| break 9 }

# a method that reads what the block answers, and a block whose last
# statement is not on the list of those that have a value
class Scan
  def scan(n) = yield(n)
end
class Shy < Scan
  def scan(...) = (super(...); seen(...))
  def seen(n) = [1, yield(n)]
end
p catch(:done) { Shy.new.scan(2) { |x| throw :done, x + 3 if x > 1; x += 1 while x < 9 } }
p catch(:done) { Shy.new.scan(2) { |x| throw :done, x + 4 if x > 1; x > 5 && throw(:done, 9) } }

# a method that takes the block by name, or hands it on
class Named < Scan
  def scan(...) = (super(...); seen(...))
  def seen(n, &b) = [1, b.call(n)]
end
class Handed < Scan
  def scan(...) = (super(...); seen(...))
  def seen(n, &b) = other(n, &b)
  def other(n) = [1, yield(n)]
end
p catch(:done) { Named.new.scan(2) { |x| throw :done, x + 5 if x > 1; x += 1 while x < 9 } }
p catch(:done) { Handed.new.scan(2) { |x| throw :done, x + 6 if x > 1; x += 1 while x < 9 } }

# a parameter that has a default
class Preset < Scan
  def scan(...) = (super(...); seen(...))
  def seen(n = 1) = [n, yield(n)]
end
p catch(:done) { Preset.new.scan(2) { |x| throw :done, x + 7 if x > 1; x } }

# a method whose parameters are not exactly what the `...` hands on: CRuby
# refuses the count where the forward would run on
class Wider < Scan
  def scan(...) = (super(...); seen(...))
  def seen(n, k) = [k, yield(n)]
end
class Bare < Scan
  def scan(...) = (super(...); seen(...))
  def seen = [1, yield(0)]
end
class Asked < Scan
  def scan(...) = (super(...); seen(...))
  def seen(n, k:) = [k, yield(n)]
end
p catch(:done) { Wider.new.scan(2) { |x| throw :done, x + 18 if x > 1; x } }
p catch(:done) { Bare.new.scan(2) { |x| throw :done, x + 19 if x > 1; x } }
p catch(:done) { Asked.new.scan(2) { |x| throw :done, x + 20 if x > 1; x } }

# a call of the method's name that hands another count
class Pair
  def join(n) = yield(n)
end
class Both < Pair
  def join(...) = (super(...); seen(...))
  def seen(n, m) = [m, yield(n)]
end
class Glue
  def join(a, b) = a + b
end
p catch(:done) { Both.new.join(2) { |x| throw :done, x + 21 if x > 1; x } }
p Glue.new.join(20, 4)

# there the block would run once more than CRuby runs it
class Extra < Reader
  def each_row(...) = (super(...); tell(...))
  def tell(n, k)
    yield(n) if block_given?
    0
  end
end
runs = 0
begin
  Extra.new.each_row(2) { |x| runs += 1; x * 3 }
rescue ArgumentError
end
p runs

# a default that reaches the block: its yield is read, and the body is not
# what reads it
class Early < Scan
  def scan(...) = (super(...); seen(...))
  def seen(n, k = yield(n))
    yield(n)
    k
  end
end
class Keyed < Scan
  def scan(...) = (super(...); seen(...))
  def seen(n, k: yield(n))
    yield(n)
    k
  end
end
class Listed < Scan
  def scan(...) = (super(...); seen(...))
  def seen(n, k = [1, yield(n)])
    yield(n)
    k
  end
end
p catch(:done) { Early.new.scan(2) { |x| throw :done, x + 12 if x > 1; x += 1 while x < 9 } }
p catch(:done) { Keyed.new.scan(2) { |x| throw :done, x + 13 if x > 1; x += 1 while x < 9 } }
p catch(:done) { Listed.new.scan(2) { |x| throw :done, x + 14 if x > 1; a, b = x, x } }

# a yield under a block of the method's own, which can be a function of its
# own where the forwarded block is not in reach
class Lazy < Scan
  def scan(...) = (super(...); seen(...))
  def seen(n)
    h = Hash.new { |hh, k| yield(k) }
    h[n]
  end
end
class Counted < Scan
  def scan(...) = (super(...); seen(...))
  def seen(n)
    h = Hash.new { |hh, k| yield(k); 0 }
    h[n]
  end
end
p catch(:done) { Lazy.new.scan(2) { |x| throw :done, x + 15 if x > 1; x * 3 } }
p catch(:done) { Counted.new.scan(2) { |x| throw :done, x + 16 if x > 1; x * 3 } }
p catch(:done) { Lazy.new.scan(2) { |x| throw :done, x + 17 if x > 1; x += 1 while x < 9 } }

# a call that finds its method at run time runs one form of it for every
# block: a block not known to run right leaves that form as it was
class Pass
  def pass(n) = yield(n)
end
class Wide < Pass
  def pass(...) = (super(...); seen(...))
  def seen(n) = [1, yield(n)]
end
class Plain
  def pass(n) = yield(n + 1)
end
[Wide.new, Plain.new].each do |o|
  p catch(:done) { o.pass(2) { |x| throw :done, x + 8 if x > 1; x += 1 while x < 9 } }
end
