# include? and member? of a String Range ask each end for to_int before
# they walk, and an end that answers an Integer makes the call cover? by
# the compare, where "ab" is past "aaa". This program gives one String,
# the Range's last end, a to_int of its own (`def hi.to_int`), which is no
# method of a class. The include? and member? of a boxed appended String
# keep the answer they had, which is that one.
hi = "aaa".dup
def hi.to_int
  0
end

h = {"k" => "a".dup, "n" => 1}
h["k"] << "b"
r = ("a"..hi)
p r.include?(h["k"])
p r.member?(h["k"])
