# casecmp and casecmp? of a String against a boxed String the program has
# appended to: the operand is a String, so they compare (they answered nil).
h = { "k" => +"AB", "n" => 1 }
h["k"] << "c"
p "abc".casecmp(h["k"]), "abc".casecmp?(h["k"])
p "abd".casecmp(h["k"]), "abb".casecmp(h["k"]), "abd".casecmp?(h["k"])

a = [+"x", 2]
a[0] << "Y"
p "XY".casecmp(a[0]), "xy".casecmp?(a[0])

# the operand is read as it is at the call
h["k"] << "D"
p "ABCd".casecmp(h["k"]), "abc".casecmp?(h["k"])

# an empty one
e = { "k" => +"", "n" => 1 }
e["k"] << ""
p "".casecmp(e["k"]), "a".casecmp(e["k"]), "".casecmp?(e["k"])

# through a method and a block
def same?(s, v) = s.casecmp?(v)
p same?("ABCD", h["k"]), same?("abc", h["k"])
p ["abcd", "zz"].map { |s| s.casecmp(h["k"]) }

# an operand that is no String still answers nil
p "abc".casecmp(h["n"]), "abc".casecmp?(h["n"]), "1".casecmp(a[1])
p "abc".casecmp(h["zz"]), "abc".casecmp?(h["zz"])
