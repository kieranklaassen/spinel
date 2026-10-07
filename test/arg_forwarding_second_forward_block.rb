# A method that keeps its `...` (its `super(...)` reaches a parent that
# yields) hands the block to every forward in its body, not to the super
# alone: `note(...)` beside `super(...)` runs under the same block.
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
  x + seen.size
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

# a callee that takes the block by name, and one that only asks
class Named < Reader
  def each_row(...) = [super(...), call_it(...), asked(...)]
  def call_it(n, &b) = b.call(n)
  def asked(n) = block_given?
end
p Named.new.each_row(2) { |x| x * 3 }

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

# a block that leaves by `next` answers both
p Loud.new.each_row(2) { |x| x > 5 ? 1 : (next 7) }

# where the forward reads the block's value, a block whose last statement is
# a loop has none to give: a method called with such a block is left as it
# was, so one that leaves by `throw` before the forward runs still builds
class Wary < Reader
  def each_row(...) = (super(...); seen(...))
  def seen(n) = [1, yield(n)]
end
class Scan
  def scan(n) = yield(n)
end
class Shy < Scan
  def scan(...) = (super(...); seen(...))
  def seen(n) = [1, yield(n)]
end
p Wary.new.each_row(2) { |x| x * 3 }
p catch(:done) { Shy.new.scan(2) { |x| throw :done, x + 3 if x > 1; x += 1 while x < 9 } }
