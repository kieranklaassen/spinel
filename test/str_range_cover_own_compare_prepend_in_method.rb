# cover? of a String Range stands on String#<=>. This program puts a <=>
# of its own ahead of String's by a prepend inside a method of the class,
# which it then calls. The class table reads a prepend written in the
# class's body, not this one: here the call runs and puts nothing ahead.
# The cover? of a boxed appended String keeps the answer it had: the one
# the program's <=> gives in CRuby.
module Up
  def <=>(o)
    1
  end
end

class String
  def self.setup
    prepend Up
  end
end

String.setup

h = {"k" => "a".dup, "n" => 1}
h["k"] << "b"
r = ("aa".."az")
p r.cover?(h["k"])
p r.cover?(h["n"])
