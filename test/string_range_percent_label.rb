# A String Range's % answers the Enumerator step(n) answers, and inspects
# under the name it was called by, as CRuby's does ("a".."e":%(2)).
r = ("a".."e")
p (r % 2)
p r.step(2)
e = r % 3
puts e.inspect
p e.to_a, e.next
p (("a"..."f") % 2).to_a
n = 4
p (r % n)
r.%(2) { |x| print x }
puts
