# include? and member? of a String Range whose two ends are all digits and
# past a machine word walk by Integers in CRuby: it asks Integer#succ for
# the next one. This program gives Integer one that steps by two, so the
# walk passes over the Range's last end. The include? and member? of a
# boxed appended String keep the answer they had, which is that one.
class Integer
  def succ
    self + 2
  end
end

h = {"k" => "9999999999999999999999".dup, "n" => 1}
h["k"] << "9"
r = ("99999999999999999999998".."99999999999999999999999")
p r.include?(h["k"])
p r.member?(h["k"])
