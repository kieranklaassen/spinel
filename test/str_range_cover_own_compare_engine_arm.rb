# cover? of a String Range stands on String#<=>. This program gives String
# a <=> of its own under a test of the engine. CRuby runs that arm; this
# compiler decides the test and leaves the arm out of the program, so the
# def is in no table. The cover? of a boxed appended String keeps the
# answer it had: the one the program's <=> gives in CRuby.
if RUBY_ENGINE == "ruby"
  class String
    def <=>(o)
      1
    end
  end
end

h = {"k" => "a".dup, "n" => 1}
h["k"] << "b"
r = ("aa".."az")
p r.cover?(h["k"])
p r.cover?(h["n"])
