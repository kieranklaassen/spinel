# member? is Enumerable's in CRuby and walks by `each`. This program
# gives Array an `each` that yields nothing, which the boxed receiver's
# switch does not ask. member? of a boxed String Array with a boxed
# appended String keeps the answer it had: nothing is walked to.
class Array
  def each
    self
  end
end

h = {"k" => "a".dup, "n" => 1}
h["k"] << "b"
bw = [["ab", "cd"], 1][0]
p bw.member?(h["k"])
