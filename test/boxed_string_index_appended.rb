# A String reached through a boxed value and read by an index the boxed
# road had no arm for (an appended String, a Float, a Float Range, true,
# an Array) answered its first character.
def t
  p yield
rescue => e
  puts "#{e.class}: #{e.message}"
end

h = { "k" => +"a", "n" => 1 }
h["k"] << "b"
m = { "c" => +"cab", "n" => 1 }
m["c"] << "ab"
g = { "c" => "cabab", "f" => 1.5, "nf" => -1.5, "t" => true, "a" => [1], "n" => 1,
      "fr" => (1.0..2.0), "fx" => (1.5...3.2), "fe" => (1.0..), "fb" => (..2.0), "fo" => (9.0..10.0),
      "sr" => ("a".."b") }

# an appended String is searched for
t { g["c"][h["k"]] }
t { g["c"].slice(h["k"]) }
t { m["c"][h["k"]] }
t { g["c"][m["c"]] }
t { h["k"][m["c"]] }

# a Float is cut to its Integer
t { g["c"][g["f"]] }
t { g["c"][g["nf"]] }
t { m["c"][g["f"]] }

# a Float Range slices by its ends cut to Integers
t { g["c"][g["fr"]] }
t { g["c"][g["fx"]] }
t { g["c"][g["fe"]] }
t { g["c"][g["fb"]] }
t { g["c"][g["fo"]] }
t { m["c"].slice(g["fr"]) }

# what has no Integer conversion raises
t { g["c"][g["t"]] }
t { g["c"][g["a"]] }
t { g["c"][g["sr"]] }

# the answer is a copy: the appended String may grow afterwards
r = g["c"][h["k"]]
h["k"] << ("z" * 5000)
GC.start
p r
t { g["c"][h["k"]] }

# the indexes that had an arm answer as they did
t { g["c"][g["n"]] }
t { g["c"]["ab"] }
t { g["c"][1..2] }
t { m["c"][g["n"]] }
t { g["c"][g["q"]] }
t { m["c"][g["q"]] }
