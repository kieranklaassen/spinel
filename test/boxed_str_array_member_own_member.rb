# member? is Enumerable's in CRuby, not Array's. This program gives
# Enumerable a member? of its own, which the boxed receiver's switch does
# not ask. member? of a boxed String Array with a boxed appended String
# keeps the answer it had: the one the program's member? gives.
module Enumerable
  def member?(x)
    false
  end
end

h = {"k" => "a".dup, "n" => 1}
h["k"] << "b"
bw = [["ab", "cd"], 1][0]
p bw.member?(h["k"])
