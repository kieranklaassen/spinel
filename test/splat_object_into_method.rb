# A splat of one object is that object, as one argument, where it is handed
# to a method of the program and the program has no way to a to_a. It arrived
# wrapped in an Array: `def one(a) = a; p one(*Foo.new(1))` printed [#<Foo 1>].
# A program that spells a to_a anywhere (`alias to_a instance_variables`)
# keeps the form it had.
class Foo
  attr_reader :n
  def initialize(n) = @n = n
  def inspect = "#<Foo #{@n}>"
end
class Sub < Foo
end
class Acc
  attr_accessor :n
  def initialize(n) = @n = n
end
class Box
  def initialize(a) = @a = a
  def a = @a
end
class Base
  def g(a) = a
end
class Kid < Base
  def g(v) = super(*v)
  def h(v) = wrap(*v)
  def wrap(a) = [a]
  def self.k(a) = a
end

def one(a) = a
def two(a, b) = [a, b]
def opt(a, b = 0) = [a, b]
def kw(a, k: 1) = [a, k]
def cls(a) = a.class
def num(a) = a.n
def bump(a) = a.n += 1
def blk(a) = yield(a)
def fwd(v) = one(*v)
def rest(*r) = r

x = Foo.new(1)
p one(*x)
p one(*Foo.new(2))
p cls(*x)
p num(*x)
p two(0, *x)
p two(*x, 9)
p opt(*x)
p kw(*x, k: 2)
p(blk(*x) { |q| [q] })
p fwd(x)
p send(:one, *x)
p Kid.k(*x)
p Kid.new.g(x)
p Kid.new.h(x)
p Box.new(*x).a
p one(*Sub.new(3))
p one(*x).equal?(x)

# the object itself, not a copy
acc = Acc.new(4)
bump(*acc)
p acc.n

# a value that may be nil is no argument when it is
some = ARGV.size < 5 ? Foo.new(5) : nil
none = ARGV.size > 5 ? Foo.new(6) : nil
p opt(*some)
begin
  one(*none)
rescue ArgumentError => e
  puts e.message
end

# too few and too many are counted
begin
  two(*x)
rescue ArgumentError => e
  puts e.message
end

# a rest parameter, as before
p rest(*x)
