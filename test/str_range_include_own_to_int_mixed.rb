# include? and member? of a String Range ask each end for to_int before
# they walk, and an end that answers an Integer makes the call cover? by
# the compare, where "ab" is past "aaa". This program gives String a
# to_int by a module of its own that String includes. The include? and
# member? of a boxed appended String keep the answer they had, which is
# that one.
module Sized
  def to_int
    0
  end
end

class String
  include Sized
end

h = {"k" => "a".dup, "n" => 1}
h["k"] << "b"
r = ("a".."aaa")
p r.include?(h["k"])
p r.member?(h["k"])
