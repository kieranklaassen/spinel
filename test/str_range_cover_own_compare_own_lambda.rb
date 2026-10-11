# cover? of a String Range stands on String#<=>. This program gives String
# a <=> of its own through a lambda of its own, which answers a Symbol it
# computes: handed on as a block, the Symbol calls the method it names,
# class_eval, on the class with a text. This compiler reads `lambda { }`
# as a Proc, runs the empty block and defines nothing. The cover? of a
# boxed appended String keeps the answer it had: the one the program's
# <=> gives in CRuby.
def lambda(&b)
  ("class_e" + "val").to_sym
end

[String, "def <=>(o) = 1"].inject(&lambda { })

h = {"k" => "a".dup, "n" => 1}
h["k"] << "b"
r = ("aa".."az")
p r.cover?(h["k"])
p r.cover?(h["n"])
