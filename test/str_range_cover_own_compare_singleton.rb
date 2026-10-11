# cover? of a String Range stands on String#<=>. This program gives one
# String, the Range's first end, a <=> of its own (`def lo.<=>`), which is
# no method of a class and so is not in the class table. The cover? of a
# boxed appended String keeps the answer it had: the one that <=> gives.
lo = "aa".dup
def lo.<=>(o)
  1
end

h = {"k" => "a".dup, "n" => 1}
h["k"] << "b"
r = (lo.."az")
p r.cover?(h["k"])
p r.cover?(h["n"])
