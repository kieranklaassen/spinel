# spinel: int64 -- assumes a 64-bit Integer (a Bignum index needs it)
# A boxed Array's index that is no Integer converts as Array#[] converts it:
# an object answers to_int, a Float or a Bignum past a word is a RangeError,
# and true is named as CRuby names it. A Rational raised TypeError, a NaN
# answered nil and a Bignum element 0.

class Ix
  def to_int = 2
end

def pick(n) = n > 0 ? {a: 1} : [10, "s", :z]

def report
  p yield
rescue TypeError, RangeError => e
  puts "#{e.class}: #{e.message}"
end

h = pick(0)
g = { "nan" => 0.0 / 0.0, "inf" => 1.0 / 0.0, "ninf" => -1.0 / 0.0, "far" => 1e30,
      "big" => 2**70, "nbig" => -(2**70), "r" => Rational(3, 2), "c" => Complex(1, 0),
      "o" => Ix.new, "t" => true, "f" => false, "fl" => 1.9, "a" => [0] }

# what converts reads an empty Array too
e = [[], 5][0]
report { e[g["r"]] }
report { e[g["c"]] }
report { e[g["o"]] }

# past a word
report { h[g["nan"]] }
report { h[g["inf"]] }
report { h[g["ninf"]] }
report { h[g["far"]] }
report { h[g["big"]] }
report { h[g["nbig"]] }
report { h[2**70] }
report { h.at(g["nan"]) }

# what converts
report { h[g["r"]] }
report { h[g["c"]] }
report { h[g["o"]] }
report { h[Rational(3, 2)] }
report { h[Ix.new] }

# true and false by their names
report { h[g["t"]] }
report { h[g["f"]] }
report { h[true] }
report { h.at(true) }
begin
  h[true] ||= 1
rescue TypeError => e
  puts "TypeError: #{e.message}"
end

# a Float in range, an Array, an Integer, a Range and nil answer as before
report { h[g["fl"]] }
report { h[-1.2] }
report { h[g["a"]] }
p h[0]
p h[-1]
p h[0..1]
report { h[nil] }
p h
