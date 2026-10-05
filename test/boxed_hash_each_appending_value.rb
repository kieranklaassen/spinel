# `each { |k, v| v << x }` over a Hash whose kind is known only at run time:
# a block parameter, a reader's answer. The push types v an Array, which is
# right for a Hash of Arrays; they are pushed in place.
h = {a: ["s"], b: ["t", "u"]}
[h].each do |g|
  g.each { |k, x| x << "z" }
  g.each_pair { |k, x| x << "y" if k == :b }
  g.each_value.with_index { |x, i| x << "w" if i == 0 }
end
p h.to_a

class Shelf
  attr_reader :rows
  def initialize; @rows = {}; end
end
s = Shelf.new
s.rows[:a] = ["s"]
s.rows.each { |k, x| x << "z" }
p s.rows.to_a

# A String out of such a Hash answers `<<` as well, and it was unboxed to a
# null Array: the push crashed. The append could only reach a copy, since a
# String is not yet shared by reference through a Hash's values, so the
# append raises NotImplementedError, in the words a Hash local is refused
# with when it is built. The rescue answers what CRuby answers, so the two
# runs agree only when spinel raised.
g = {a: +"q"}
[g].each do |f|
  r = begin
    f.each { |k, x| x << "z" }
    f.to_a
  rescue NotImplementedError
    [[:a, "qz"]]
  end
  p r
end

t = Shelf.new
t.rows[:a] = +"q"
r = begin
  t.rows.each_pair { |k, x| x << "z" }
  t.rows.to_a
rescue NotImplementedError
  [[:a, "qz"]]
end
p r

r = begin
  t.rows.each_value.with_index { |x, i| x << "z" }
  t.rows.to_a
rescue NotImplementedError
  [[:a, "qzz"]]
end
p r

# The raise is the append's: a block that never reaches it for the String
# runs to its end.
m = {a: +"q", b: ["s"]}
[m].each do |f|
  f.each { |k, x| x << "z" if k == :b }
  f.each_value.with_index { |x, i| x << "y" if i == 1 }
end
p m.to_a
