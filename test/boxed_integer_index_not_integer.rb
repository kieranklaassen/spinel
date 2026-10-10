# spinel: int64 -- assumes a 64-bit Integer (Bignum operands need it)
# Integer#[] reads one bit. A boxed Integer read by a boxed index that is
# neither an Integer nor a Float (a Rational, nil, true, a Bignum) answered
# bit 0.

def t
  p yield
rescue => e
  puts "#{e.class}: #{e.message}"
end

def bit(x, k) = x[k]

g = { "n" => 5, "m" => -6, "b" => 2**70, "f" => 1.5, "nf" => -1.5,
      "far" => 1e30, "nan" => 0.0 / 0.0,
      "r" => Rational(5, 2), "r1" => Rational(3, 2), "nr" => Rational(-3, 2),
      "r70" => Rational(141, 2), "c" => Complex(1, 0), "ci" => Complex(1, 1),
      "bi" => 2**70, "nbi" => -(2**70),
      "t" => true, "fa" => false, "nil" => nil, "i" => 2, "ir" => (0..1),
      "cf" => Complex(1e30, 0), "rf" => Rational(10**30, 1) }

# a Rational is cut to its Integer, and a Complex with no imaginary part
# is the Integer it converts to
t { bit(g["n"], g["r"]) }
t { bit(g["n"], g["r1"]) }
t { bit(g["m"], g["r1"]) }
t { bit(g["n"], g["nr"]) }
t { bit(g["n"], g["c"]) }
t { bit(g["m"], g["c"]) }
t { bit(g["n"], g["ci"]) }

# an index past every bit, a Bignum, reads the sign
t { bit(g["n"], g["bi"]) }
t { bit(g["m"], g["bi"]) }
t { bit(g["m"], g["nbi"]) }

# so does a Complex or a Rational that converts to an Integer that large
t { bit(g["m"], g["cf"]) }
t { bit(g["n"], g["rf"]) }
t { bit(g["m"], g["rf"]) }

# what has no conversion raises
t { bit(g["n"], g["t"]) }
t { bit(g["n"], g["fa"]) }
t { bit(g["n"], g["nil"]) }

# a Bignum receiver: the same, but an index past a word that is no Bignum
# is a RangeError
t { bit(g["b"], g["r70"]) }
t { bit(g["b"], g["r1"]) }
t { bit(g["b"], g["bi"]) }
t { bit(g["b"], g["cf"]) }
t { bit(g["b"], g["rf"]) }
t { bit(g["b"], g["nil"]) }
t { bit(g["b"], g["t"]) }

# an Integer, a Float and an Integer Range answer as before
t { bit(g["n"], g["i"]) }
t { bit(g["n"], g["f"]) }
t { bit(g["n"], g["nf"]) }
t { bit(g["n"], g["far"]) }
t { bit(g["n"], g["nan"]) }
t { bit(g["n"], g["ir"]) }
t { bit(g["b"], g["i"]) }
t { bit(g["b"], g["f"]) }

# nil in a slot typed for another kind of index raises as nil does
z = ARGV.size
bn = z == 0 ? nil : 2**70
fl = z == 0 ? nil : 1.5
rg = z == 0 ? nil : (0..1)
ra = z == 0 ? nil : Rational(5, 2)
ar = z == 0 ? nil : [1]
n = g["n"]
b = g["b"]
p((n[bn] rescue "TypeError"))
p((n[fl] rescue "TypeError"))
p((n[rg] rescue "TypeError"))
p((n[ra] rescue "TypeError"))
p((n[ar] rescue "TypeError"))
p((b[fl] rescue "TypeError"))

# fresh Bignum receivers, each read by two Rationals
k = 0
s = 0
r = g["r"]
r70 = g["r70"]
while k < 200
  x = [2**70 + k, nil][0]
  s += x[r] + x[r70]
  k += 1
end
p s

# a receiver that is no local: an element of an Array, a global, an
# instance variable, a class variable, a local a block shares
v = [5, Rational(3, 2), 2**70, "s"]
p v[0][v[1]]
p v[0][v[2]]
$x = v[0]
p $x[v[1]]
r1 = v[1]
t { $x[r1] }
t { n[r1] }
class Plain
  def initialize(x) = (@x = x)
  def iv(k) = @x[k]
  def other(k) = @x[@k = k]
  def cv(k) = (@@c = @x; @@c[k])
end
p Plain.new(v[0]).iv(v[1])
p Plain.new(v[0]).other(v[1])
p Plain.new(v[0]).cv(v[2])
# a constant
KR = v[1]
p $x[KR]

# a receiver its own index assigns can be read after the index ran: these
# answered CRuby's bit, and they are read as they were. A global, an
# instance variable and a class variable
$m = g["m"]
$x = v[0]
p $x[begin; $x = $m; v[1]; end]
$x = v[0]
p $x[v[1].tap { $x = $m }]
$x = v[0]
p $x[($x = $m) && v[1]]
class Holder
  def initialize(x, m, k) = (@x = x; @m = m; @k = k)
  def iv = @x[begin; @x = @m; @k; end]
  def blk = @x[@k.tap { @x = @m }]
  def cv = (@@c = @x; @@c[begin; @@c = @m; @k; end])
end
p Holder.new(v[0], $m, v[1]).iv
p Holder.new(v[0], $m, v[1]).blk
p Holder.new(v[0], $m, v[1]).cv
# an element of an Array, and what a method answers
w = [4, "s"]
p w[0][case w.size when 2 then w[0] = 2; v[1] else v[1] end]
class Box
  attr_accessor :v
  def initialize(v) = (@v = v)
end
o = Box.new(v[0])
p o.v[case w.size when 2 then o.v = -6; v[1] else v[1] end]

# so is a global whose index calls a Proc by [] through a boxed element,
# where the Proc assigns it: a lambda, a Method, a curried lambda, a proc
a = [->(i) { $x = $m; i }, 0]
def setx(i) = ($x = $m; i)
c = [method(:setx), ->(i, j) { $x = $m; j }.curry, proc { |i| $x = $m; i }, 0]
$x = v[0]
p $x[begin; a[0][0]; v[1]; end]
$x = v[0]
p $x[begin; c[0][0]; v[1]; end]
$x = v[0]
p $x[begin; c[1][0][0]; v[1]; end]
$x = v[0]
p $x[begin; c[2][0]; v[1]; end]
p $x
