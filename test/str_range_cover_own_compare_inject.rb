# cover? of a String Range stands on String#<=>. This program gives String
# a <=> of its own by an inject handed a name it computes: the class and
# a text, folded by class_eval. This compiler does not call a method by a
# name that is a value: it raises NoMethodError here, and the program
# goes on. The cover? of a boxed appended String keeps the answer it had:
# the one the program's <=> gives in CRuby.
begin
  [String, "def <=>(o) = 1"].inject("class_e" + "val")
rescue NoMethodError
end

h = {"k" => "a".dup, "n" => 1}
h["k"] << "b"
r = ("aa".."az")
p r.cover?(h["k"])
p r.cover?(h["n"])
