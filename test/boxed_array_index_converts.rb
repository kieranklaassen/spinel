# spinel: int64 -- assumes a 64-bit Integer (a Bignum index needs it)
# A boxed Array's index that is no Integer converts as Array#[] converts it:
# a Rational or a Complex reads the element, a Bignum past a word is a
# RangeError, and true is named as CRuby names it. A Rational raised
# TypeError and a Bignum answered element 0.

def pick(n) = n > 0 ? {a: 1} : [10, "s", :z]

def report
  p yield
rescue TypeError, RangeError => e
  puts "#{e.class}: #{e.message}"
end

h = pick(0)
g = { "nan" => 0.0 / 0.0, "inf" => 1.0 / 0.0, "far" => 1e30,
      "big" => 2**70, "nbig" => -(2**70), "r" => Rational(3, 2), "c" => Complex(1, 0),
      "t" => true, "f" => false, "fl" => 1.9, "a" => [0], "k" => Integer,
      "cf" => Complex(1e30, 0), "ncf" => Complex(-1e30, 0), "rf" => Rational(10**30, 1) }

# what converts reads an empty Array too
e = [[], 5][0]
report { e[g["r"]] }
report { e[g["c"]] }

# a Bignum is past a word
report { h[g["big"]] }
report { h[g["nbig"]] }
report { h[2**70] }

# what converts to an Integer past a word: the Bignum's RangeError
report { h[g["cf"]] }
report { h[g["ncf"]] }
report { h[g["rf"]] }
report { e[g["cf"]] }

# the smallest Integer fits a word: as a Bignum too it is past the Array
m = { "min" => -(2**63), "s" => "x" }
report { h[m["min"]] }

# what converts
report { h[g["r"]] }
report { h[g["c"]] }
report { h[Rational(3, 2)] }

# true and false by their names
yes = 1 < 2
report { h[g["t"]] }
report { h[g["f"]] }
report { h[yes] }

# a Float, an Array, a Class, an Integer, a Range and nil answer as before
report { h[g["fl"]] }
report { h[-1.2] }
report { h[g["nan"]] }
report { h[g["inf"]] }
report { h[g["far"]] }
report { h[g["a"]] }
report { h[g["k"]] }
p h[0]
p h[-1]
p h[0..1]
report { h[nil] }
p h

# a global, an instance variable or a class variable that its own index
# assigns can be read after the index ran: a Hash read by a Bignum is nil,
# and so it was, by the Array the index assigned
gh = [{ 1 => "one" }, [nil, 2], 2**70]
$x = gh[0]
report { $x[begin; $x = gh[1]; gh[2]; end] }
$x = gh[0]
report { $x[gh[2].tap { $x = gh[1] }] }
class Slot
  def initialize(g) = (@g = g; @x = g[0])
  def iv = @x[begin; @x = @g[1]; @g[2]; end]
  def self.cv(g) = (@@c = g[0]; @@c[begin; @@c = g[1]; g[2]; end])
end
report { Slot.new(gh).iv }
report { Slot.cv(gh) }
