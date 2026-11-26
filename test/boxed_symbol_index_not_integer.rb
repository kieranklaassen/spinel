# Symbol#[] is String#[] on the Symbol's name. A boxed Symbol read by a
# boxed index that is no Integer, String, Integer Range, Regexp or nil (a
# Float, a Float Range, true, an Array, a String the program appends to)
# answered the name's first character.

class Ix
  def to_int = 1
end

def t
  p yield
rescue => e
  puts "#{e.class}: #{e.message}"
end

h = { "k" => +"t", "n" => 1 }
h["k"] << "o"
g = { "s" => :stone, "f" => 1.5, "nf" => -1.5, "r" => Rational(3, 2), "o" => Ix.new,
      "t" => true, "fl" => false, "nil" => nil, "a" => [1], "hh" => {a: 1},
      "fr" => (1.0..2.0), "fx" => (1.5...3.2), "fe" => (1.0..), "fb" => (..2.0), "sr" => ("a".."b"),
      "n" => 1, "ir" => (1..2), "re" => /o./ }

# a Float is cut to its Integer, an object answers to_int
t { g["s"][g["f"]] }
t { g["s"][g["nf"]] }
t { g["s"][g["r"]] }
t { g["s"][g["o"]] }
t { g["s"].slice(g["f"]) }

# what has no conversion is a TypeError
t { g["s"][g["t"]] }
t { g["s"][g["fl"]] }
t { g["s"][g["a"]] }
t { g["s"][g["hh"]] }

# a Float Range slices by its ends cut to Integers; a String Range does not
t { g["s"][g["fr"]] }
t { g["s"][g["fx"]] }
t { g["s"][g["fe"]] }
t { g["s"][g["fb"]] }
t { g["s"][g["sr"]] }

# an appended String is searched for
t { g["s"][h["k"]] }
t { g["s"].slice(h["k"]) }

# an Integer, an Integer Range, a Regexp and nil answer as before
t { g["s"][g["n"]] }
t { g["s"][g["ir"]] }
t { g["s"][g["re"]] }
t { g["s"][g["nil"]] }
