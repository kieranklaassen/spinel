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

# a parameter the forward would fill that has a default
class Preset < Scan
  def scan(...) = (super(...); seen(...))
  def seen(n = 1) = [n, yield(n)]
end
p catch(:done) { Preset.new.scan(2) { |x| throw :done, x + 7 if x > 1; x } }

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
