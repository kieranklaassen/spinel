# cover? of a String Range stands on String#<=>. This program prepends to
# String a module that prepends another in turn, and the <=> is the
# second's: the class table reads what a prepended module defines and
# includes, not what it prepends. The cover? of a boxed appended String
# keeps the answer it had: the one the program's <=> gives.
module Up
  def <=>(o)
    1
  end
end

module Mid
  prepend Up
end

class String
  prepend Mid
end

h = {"k" => "a".dup, "n" => 1}
h["k"] << "b"
r = ("aa".."az")
p r.cover?(h["k"])
p r.cover?(h["n"])
