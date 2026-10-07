# String#[] and #slice by an index whose kind is known only at run time:
# a String, a Range or a Regexp raised TypeError (no implicit conversion
# into Integer).
def t
  p yield
rescue => e
  puts "#{e.class}: #{e.message}"
end

h = { "k" => +"a", "n" => 1 }
h["k"] << "b"
g = { "k" => "ab", "z" => "zz", "e" => "", "r" => (1..2), "o" => (9..10), "x" => /a(.)/,
      "n" => 1, "f" => 1.5, "s" => :ab }
s = "cabab"

# a String is searched for
t { s[g["k"]] }
t { s[g["z"]] }
t { s[g["e"]] }
t { s.slice(g["k"]) }
t { s[h["k"]] }

# a Range slices
t { s[g["r"]] }
t { s[g["o"]] }
t { s.slice(g["r"]) }

# a Regexp answers its first match and sets the match variables
t { s[g["x"]] }
p $~[0], $1
t { s.slice(g["x"]) }
t { "zzz"[g["x"]] }
p $~

# other receivers
u = +"cab"
u << "ab"
t { u[g["k"]] }
t { "cabab"[g["r"]] }
t { ("ca" + "bab")[g["x"]] }
t { :cabab[g["k"]] }
t { :cabab.slice(g["r"]) }
t { [1, "ab"][1].then { |i| s[i] } }

# the answer for a String is a new String, as CRuby's is
w = s[g["k"]]
w << "!"
p w, g["k"], s[g["k"]].frozen?

# the answer for an appended String is a copy
r = s[h["k"]]
h["k"] << ("z" * 5000)
GC.start
p r

# an Integer, a Float and what has no Integer conversion are as before
t { s[g["n"]] }
t { s[g["f"]] }
t { s[g["q"]] }
t { s[g["s"]] }
