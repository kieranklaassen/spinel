# cover? of a String Range stands on String#<=>. This program gives String
# a <=> of its own by a class_eval on the class held in a local. This
# compiler does not take such a block: it writes a raise of
# NotImplementedError in the call's place, and the program, which rescues
# it, goes on without the method. The cover? of a boxed appended String
# keeps the answer it had: the one the program's <=> gives in CRuby.
k = String
begin
  k.class_eval do
    def <=>(o)
      1
    end
  end
rescue NotImplementedError
end

h = {"k" => "a".dup, "n" => 1}
h["k"] << "b"
r = ("aa".."az")
p r.cover?(h["k"])
p r.cover?(h["n"])
