# A splat of one value that has no to_a is that value, as one argument, in the
# argument list built for a yield or a proc. It spread to nothing there: the
# block bound nil. This holds in a program that gives nothing a to_a of its
# own: one `def to_a` anywhere, and a splatted value keeps the form it had.
# A lambda's call and a Method's count their arguments and are left as they
# were.
class Foo
  def initialize(n) = @n = n
  def inspect = "#<Foo #{@n}>"
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

# into a proc
pr = proc { |a| a }
rest = proc { |*r| r }
x = Foo.new(4)
n = 6
p pr.call(*n)
p pr.(*x)
p pr.yield(*n)
p pr.yield(*x)
p pr.call(*mk(5))
p rest.call(*:k)
p rest.call(*1.5)

# a boxed value is decided when it runs
vals = [7, :c, 2.5, true, false, Foo.new(8), Foo]
vals.each { |v| p(one(v) { |a| a }) }
vals.each { |v| p pr.call(*v) }
p rest.call(*vals[1])

# an Array, a Hash, a Range, a Struct and nil spread as before
p(one(nil) { |a| a })
p rest.call(*nil)
p(one([1, 2]) { |a, b| [a, b] })
p rest.call(*[3, 4])
p rest.call(*(1..3))
p rest.call(*{ a: 1 })
pair = Pair.new(1, 2)
p rest.call(*pair)
mixed = [[1, 2], nil, (5..6), { k: 1 }, Pair.new(8, 9)]
mixed.each { |v| p rest.call(*v) }

# the receiver is read first, once: an operand that writes the local
# does not change which Proc is called, and a Proc reached through a
# second local takes the value as the first does
lam = lambda { |a| [:la, a] }
tag = proc { |a| [:pr, a] }
held = tag
sym = :k
p held.call(*(held = lam; sym))
idt = proc { |a| a }
second = idt
flt = 1.5
p second.call(*flt) + 1

# an ivar is read as a local is: where it stands, unless the operand's
# method gives it another Proc
class Holder
  def initialize
    @f = proc { |a| [:iv, a] }
    @g = lambda { |a| [:la, a] }
  end
  def swap; @f = @g; 5; end
  def one(v) = @f.call(*v)
  def swapped = @f.call(*swap)
end
hd = Holder.new
p hd.one(3)
p hd.swapped
