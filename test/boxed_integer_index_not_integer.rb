# spinel: int64 -- assumes a 64-bit Integer (Bignum operands need it)
# Integer#[] reads one bit. A boxed Integer read by a boxed index that is no
# Integer (a Float, nil, true, an Array, a Bignum) answered bit 0.

class Ix
  def to_int = 2
end

def t
  p yield
rescue => e
  puts "#{e.class}: #{e.message}"
end

g = { "n" => 5, "m" => -6, "b" => 2**70, "f" => 1.5, "f2" => 2.9, "nf" => -1.5,
      "far" => 1e30, "nfar" => -1e30, "nan" => 0.0 / 0.0, "inf" => 1.0 / 0.0,
      "r" => Rational(5, 2), "o" => Ix.new, "bi" => 2**70, "nbi" => -(2**70),
      "t" => true, "nil" => nil, "a" => [1], "f70" => 70.5, "i" => 2, "ir" => (0..1) }

# a Float is cut to its Integer, an object answers to_int
t { g["n"][g["f"]] }
t { g["n"][g["f2"]] }
t { g["m"][g["f"]] }
t { g["n"][g["nf"]] }
t { g["n"][g["r"]] }
t { g["n"][g["o"]] }

# an index past every bit, a Float that large or a Bignum, reads the sign
t { g["n"][g["far"]] }
t { g["m"][g["far"]] }
t { g["m"][g["nfar"]] }
t { g["n"][g["bi"]] }
t { g["m"][g["bi"]] }
t { g["m"][g["nbi"]] }

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
t { g["b"][g["nan"]] }
t { g["b"][g["nil"]] }
t { g["b"][g["t"]] }

# an Integer and an Integer Range answer as before
t { g["n"][g["i"]] }
t { g["n"][g["ir"]] }
t { g["b"][g["i"]] }
