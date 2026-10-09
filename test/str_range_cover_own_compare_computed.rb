# cover? of a String Range stands on String#<=>. This program gives String
# a <=> of its own under a name it computes, which the compiler does not
# read. The cover? of a boxed appended String keeps the answer it had: the
# one the program's <=> gives.
class String
  define_method(("<" + "=>").to_sym) { |o| 1 }
end

h = {"k" => "a".dup, "n" => 1}
h["k"] << "b"
r = ("aa".."az")
p r.cover?(h["k"])
p r.cover?(h["n"])
