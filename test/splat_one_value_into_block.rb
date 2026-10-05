# A splat of one value that has no to_a is that value, as one argument, in the
# argument list built for a yield, a proc or a lambda. It spread to nothing
# there: the block bound nil and a lambda raised ArgumentError.
class Foo
  def initialize(n) = @n = n
  def inspect = "#<Foo #{@n}>"
end
class Bar
  def initialize(n) = @n = n
  def to_a = [@n, @n + 1]
end
class Quiet
  def inspect = "#<Quiet>"
  def to_a = nil
end
Pair = Struct.new(:l, :r)

def one(v) = yield(*v)
def blk(v, &b) = b.call(*v)
def mk(n) = Foo.new(n)

# into a yield
p(one(5) { |a| a })
p(one(1.5) { |a| a })
p(one(:k) { |a| a })
p(one(ARGV.size < 9) { |a| a })
p(one(ARGV.size > 9) { |a| a })
p(one(Foo) { |a| a })
p(one(Foo.new(1)) { |a| a })
p(one(mk(2)) { |a| a })
p(one(5) { |a, b| [a, b] })
p(one(5) { |*r| r })
p(one(5) { |a, b = 7| [a, b] })
p(blk(:k) { |a| a })
one(Foo.new(3)) { |a| p a }

# into a proc and a lambda
pr = proc { |a| a }
la = lambda { |a| a }
rest = proc { |*r| r }
x = Foo.new(4)
n = 6
p pr.call(*n)
p pr.(*x)
p la.call(*n)
p la.call(*x)
p la.call(*mk(5))
p rest.call(*:k)
p rest.call(*1.5)

# a boxed value is decided when it runs
vals = [7, :c, 2.5, true, false, Foo.new(8), Foo]
vals.each { |v| p(one(v) { |a| a }) }
vals.each { |v| p la.call(*v) }
p rest.call(*vals[1])

# what has a to_a, and nil, spread as before
p(one(nil) { |a| a })
p rest.call(*nil)
p(one([1, 2]) { |a, b| [a, b] })
p rest.call(*[3, 4])
p rest.call(*(1..3))
p rest.call(*{ a: 1 })
p rest.call(*Bar.new(3))
pair = Pair.new(1, 2)
p rest.call(*pair)
mixed = [[1, 2], nil, (5..6), { k: 1 }, Bar.new(7), Pair.new(8, 9)]
mixed.each { |v| p rest.call(*v) }

# a to_a that answers nil leaves the value itself
q = [Quiet.new, 1][0]
p rest.call(*q)
