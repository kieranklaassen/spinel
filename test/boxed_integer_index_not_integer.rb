# spinel: int64 -- assumes a 64-bit Integer (Bignum operands need it)
# Integer#[] reads one bit. A boxed Integer read by a boxed index that is no
# Integer (a Float, nil, true, an Array, a Bignum) answered bit 0.

def t
  p yield
rescue => e
  puts "#{e.class}: #{e.message}"
end

g = { "n" => 5, "m" => -6, "b" => 2**70, "f" => 1.5, "f2" => 2.9, "nf" => -1.5,
      "far" => 1e30, "nfar" => -1e30, "nan" => 0.0 / 0.0, "inf" => 1.0 / 0.0,
      "r" => Rational(5, 2), "bi" => 2**70, "nbi" => -(2**70),
      "t" => true, "nil" => nil, "a" => [1], "f70" => 70.5, "i" => 2, "ir" => (0..1),
      "cf" => Complex(1e30, 0), "rf" => Rational(10**30, 1) }

# a Float is cut to its Integer, and so is a Rational
t { g["n"][g["f"]] }
t { g["n"][g["f2"]] }
t { g["m"][g["f"]] }
t { g["n"][g["nf"]] }
t { g["n"][g["r"]] }

# an index past every bit, a Float that large or a Bignum, reads the sign
t { g["n"][g["far"]] }
t { g["m"][g["far"]] }
t { g["m"][g["nfar"]] }
t { g["n"][g["bi"]] }
t { g["m"][g["bi"]] }
t { g["m"][g["nbi"]] }

# so does a Complex or a Rational that converts to an Integer that large
t { g["m"][g["cf"]] }
t { g["n"][g["rf"]] }
t { g["m"][g["rf"]] }

# what has no conversion raises
t { g["n"][g["nan"]] }
t { g["n"][g["inf"]] }
t { g["n"][g["t"]] }
t { g["n"][g["nil"]] }
t { g["n"][g["a"]] }

# a Bignum receiver: the same, but a Float past a word is a RangeError
t { g["b"][g["f70"]] }
t { g["b"][g["bi"]] }
t { g["b"][g["far"]] }
t { g["b"][g["cf"]] }
t { g["b"][g["rf"]] }
t { g["b"][g["nan"]] }
t { g["b"][g["nil"]] }
t { g["b"][g["t"]] }

# an Integer and an Integer Range answer as before
t { g["n"][g["i"]] }
t { g["n"][g["ir"]] }
t { g["b"][g["i"]] }

# nil in a slot typed for another kind of index raises as nil does
z = ARGV.size
bn = z == 0 ? nil : 2**70
fl = z == 0 ? nil : 1.5
rg = z == 0 ? nil : (0..1)
ra = z == 0 ? nil : Rational(5, 2)
ar = z == 0 ? nil : [1]
t { g["n"][bn] }
t { g["n"][fl] }
t { g["n"][rg] }
t { g["n"][ra] }
t { g["n"][ar] }
t { g["b"][fl] }

# fresh Bignum receivers, each read by two Floats
k = 0
s = 0
while k < 200
  x = [2**70 + k, nil][0]
  s += x[g["f"]] + x[70.5]
  k += 1
end
p s

# a global, an instance variable or a class variable the index assigns is
# read as it was: these three answered CRuby's bit
$x = g["n"]
t { $x[($x = g["m"]; g["f"])] }
class Holder
  def initialize(g) = (@g = g; @x = g["n"])
  def iv = @x[(@x = @g["m"]; @g["f"])]
  def cv = (@@c = @g["n"]; @@c[(@@c = @g["m"]; @g["bi"])])
  def other = (@k = -1.5; @x[@k = @k + 3.0])
end
t { Holder.new(g).iv }
t { Holder.new(g).cv }
# an index that assigns another variable by arithmetic is read as any other
t { Holder.new(g).other }

# so is one whose index calls a Proc by [] through a boxed element, where
# the Proc assigns the receiver: by a Float, by a Bignum, the index being
# the call itself, then a Method, a curried lambda and a proc
$new = g["m"]
a = [g["n"], g["f"], ->(i) { $x = $new; i }, g["bi"], ->(i) { $x = $new; 1.5 }]
$x = a[0]
t { $x[(a[2][0]; a[1])] }
$x = a[0]
t { $x[(a[2][0]; a[3])] }
$x = a[0]
t { $x[a[4][0]] }
def setx(i) = ($x = $new; i)
b = [method(:setx), ->(i, j) { $x = $new; j }.curry, proc { |i| $x = $new; i }, 0]
$x = a[0]
t { $x[(b[0][0]; a[1])] }
$x = a[0]
t { $x[(b[1][0][0]; a[1])] }
$x = a[0]
t { $x[(b[2][0]; a[1])] }
p $x
class Keeper
  def initialize(g) = (@g = g; @x = g["n"])
  def swap = (@x = @g["m"])
  def iv(l) = @x[(l[0][0]; l[1])]
  def self.swap(g) = (@@c = g["m"])
  def self.cv(g, l) = (@@c = g["n"]; @@c[(l[0][0]; l[1])])
end
k = Keeper.new(g)
t { k.iv([->(i) { k.swap; i }, g["f"]]) }
t { Keeper.cv(g, [->(i) { Keeper.swap(g); i }, g["f"]]) }
# an index that is a constant leaves the variable as it is: bit 1 of 5
KF = 1.5
$x = g["n"]
t { $x[KF] }
