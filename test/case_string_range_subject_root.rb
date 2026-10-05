# A String Range case subject is held while its when operands run.
# The subject is a C struct of two Strings kept in a temporary, and a when
# operand that allocates collected a String only that temporary held. Each
# round sets a Range with an end made in place against operands made in
# place, none of which it matches: as a statement, as a value, and after
# an operand has reassigned the local the subject was read from.
def fresh(i) = ["s" + i.to_s, [i, i + 1], ("k" + i.to_s).to_sym][i % 3]
hit = 0
miss = 0
out = []
300.times do |i|
  case ("a".."c" + i.to_s)
  when fresh(i + 1), fresh(i) then hit += 1
  else miss += 1
  end
  out << case ("a".."c" + i.to_s)
         when fresh(i) then "h" + i.to_s
         when fresh(i + 2) then "g" + i.to_s
         else "m" + i.to_s
         end
  r = ("a".."c" + i.to_s)
  case r
  when (r = ("x".."y"); fresh(i)) then hit += 1
  else miss += 1
  end
end
p hit, miss
p out.size, out.first(3), out.last
