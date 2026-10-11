# include? and member? of a String Range whose two ends are all digits and
# past a machine word walk by Integers in CRuby: for a Range without its
# end it asks Integer#< whether to go on. This program gives Integer one
# that answers false, so the walk yields nothing. The include? and member?
# of a boxed appended String keep the answer they had, which is that one.
class Integer
  def <(o)
    false
  end
end

h = {"k" => "9999999999999999999999".dup, "n" => 1}
h["k"] << "8"
r = ("99999999999999999999998"..."99999999999999999999999")
p r.include?(h["k"])
p r.member?(h["k"])
