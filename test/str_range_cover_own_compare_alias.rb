# cover? of a String Range stands on String#<=>. This program gives String
# a <=> of its own by an alias to a builtin, which is no method of the
# program in the class table. The cover? of a boxed appended String keeps
# the answer it had: the one the program's <=> gives.
class String
  alias <=> index
end

h = {"k" => "a".dup, "n" => 1}
h["k"] << "b"
r = ("aa".."az")
p r.cover?(h["k"])
