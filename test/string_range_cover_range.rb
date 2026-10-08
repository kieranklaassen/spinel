# cover? of a String Range given a String Range asks whether the argument's
# members all lie within the receiver, by the ends where they decide it.
r = ("a".."e")
p r.cover?("b".."c")
p r.cover?("b".."f")
p r.cover?("b"..."e")
p ("a"..."e").cover?("b".."e")
p ("a"..."e").cover?("b"..."e")
a = ("b".."d")
p r.cover?(a)

# an empty argument holds nothing to cover
p r.cover?("c".."b")
p r.cover?("c"..."c")
p ("9".."11").cover?("10".."11")

# an excluded end past the receiver's: the argument's greatest member decides
p r.cover?("b"..."f")
p ("a".."z").cover?("y"..."zz")
p ("A".."Z").cover?("B"..."a")

# an open side is covered only by an open side
p ("a"..).cover?("b".."c")
p ("a"..).cover?("b"..)
p r.cover?("b"..)
p (.."e").cover?("b".."c")
p r.cover?(.."c")
p ("a"...).cover?("b"..)
begin
  p (.."b").cover?(..."c")
rescue RangeError => e
  puts e.message
end

def within(r, a)
  r.cover?(a)
end
p within(("a".."e"), ("b".."c"))
p within(("a".."e"), ("b".."z"))

# === and include? ask about one member, and a Range is none
p r === ("b".."c")
p r.include?("b".."c")

# the ends are compared as whole Strings, past a NUL
p ("a\0b".."a\0d").cover?("a\0c".."a\0c")
p ("a\0b".."a\0d").cover?("a\0e".."a\0f")
p ("a\0b".."a\0d").cover?("a\0a".."a\0c")
