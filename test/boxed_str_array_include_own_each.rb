# include? is Array's own in CRuby, but CRuby walks by `each` to make what
# is the receiver here (a blockless to_enum is an Enumerator there, and
# entries is Enumerable's) and to run the block around the last call. This
# program gives Array an `each` that yields nothing, which the boxed
# receiver's switch does not ask. include? with a boxed appended String
# keeps the answers it had: nothing is walked to.
class Array
  def each
    self
  end
end

h = {"k" => "a".dup, "n" => 1}
h["k"] << "b"
bw = [["ab", "cd"].to_enum, 1][0]
p bw.include?(h["k"])
be = [["ab", "cd"].enum_for, 1][0]
p be.include?(h["k"])
bn = [["ab", "cd"].entries, 1][0]
p bn.include?(h["k"])
ba = [["ab", "cd"], 1][0]
n = 0
[1].each { |v| n += 1 if ba.include?(h["k"]) }
p n
