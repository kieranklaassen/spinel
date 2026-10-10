# include? and member? of a String Range ask each end for to_int before
# they walk, and an end that answers an Integer makes the call cover? by
# the compare, where "ab" is past "aaa". A String has no to_int, so the
# question goes to method_missing: this program gives String one that
# answers 0 to it. The include? and member? of a boxed appended String
# keep the answer they had, which is that one.
class String
  def method_missing(name, *args)
    name.to_s.start_with?("to_in") ? 0 : super
  end
end

h = {"k" => "a".dup, "n" => 1}
h["k"] << "b"
r = ("a".."aaa")
p r.include?(h["k"])
p r.member?(h["k"])
