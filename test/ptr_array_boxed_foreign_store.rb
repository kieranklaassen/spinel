# A boxed value pushed or `[]=`-stored into an Array of one class is unboxed as
# an object of that class. Where nothing proves it one, the Array holds every
# value, as it does for a String stored by its type: a String stored through
# the box read back nil, and an object of another class was read through this
# class's layout.
def echo(x) = x
p echo(9)          # echo's return is boxed from here on

class K
  def initialize(n) = @n = n
  def n = @n
end
class K2 < K
  def n = super + 100
end
class J
  def n = 9
end

t = [K.new(1)]
t << echo("s")
p t[1]
t << echo(J.new)
p t[2].n
p t.size

u = [K.new(1), K.new(2)]
u[0] = echo(1.5)
p u[0]
p u[1].n

v = [K.new(1)]
v.push(K.new(3), echo(:sym))
v.append(echo([1, 2]))
p v[2], v[3]
p v[1].n

# a value out of a Hash of mixed values, and an Object
d = [K.new(1)]
h = { a: "s", b: J.new }
d << h[:a]
d << h[:b]
d << Object.new
p d[1], d[2].n, d[3].class

# an object of the class above is no element of an Array of the class beneath
w = [K2.new(1)]
w << echo(K.new(4))
p w.map { |e| e.n }

# through a parameter, a block and an instance variable
def add(a, x) = a << x
a = [K.new(1)]
add(a, echo("s"))
add(a, echo(J.new))
p a[1], a[2].n

b = [K.new(1)]
[echo(5), echo(J.new)].each { |x| b << x }
p b[1], b[2].n

class Bag
  attr_reader :ks
  def initialize = @ks = [K.new(1)]
  def add(x) = @ks << x
end
bag = Bag.new
bag.add(echo("s"))
bag.add(echo(K.new(6)))
p bag.ks[1], bag.ks[2].n

# a value proved an object of the class keeps the Array as it was: the method
# answers its own parameter, here and through a local
c = [K.new(1)]
c << echo(K.new(2))
x = echo(K2.new(3))
c << x
c[0] = echo(nil)
p c[0]
p c[1].n, c[2].n
p c[2].class
