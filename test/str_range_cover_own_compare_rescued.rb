# cover? of a String Range stands on String#<=>. This program gives String
# a <=> of its own by a call on the class, which this compiler does not
# perform: it raises NoMethodError here, and the program goes on. The
# cover? of a boxed appended String keeps the answer it had: the one the
# program's <=> gives in CRuby.
begin
  String.define_method(:<=>) { |o| 1 }
rescue NoMethodError
end

h = {"k" => "a".dup, "n" => 1}
h["k"] << "b"
r = ("aa".."az")
p r.cover?(h["k"])
p r.cover?(h["n"])
