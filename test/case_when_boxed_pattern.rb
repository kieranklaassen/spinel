# A `when` whose pattern is held boxed -- a parameter given several kinds, a
# block parameter, an element of a table, a Hash value, an instance variable
# -- asks the pattern `===`, as a pattern written in place does: a Range
# covers, a Regexp matches, a Class tests membership. Only a Proc was asked;
# the rest were compared with ==, so none of them ever matched.
class Pt
  attr_reader :x
  def initialize(x) = @x = x
  def ==(o) = o.is_a?(Pt) && o.x == x
end
class Pt3 < Pt; end
module Tagged; end
class Box; include Tagged; end

def kind(v, pat)
  case v
  when pat then :hit
  else :miss
  end
end
p [kind(2, 1..3), kind(7, 1..3), kind(3, 1...3), kind(2.5, 1..3), kind(nil, 1..3), kind("b", 1..3)]
p [kind(9, (5..)), kind(2, (..3)), kind(2.5, 1.0..3.0), kind(4, 1.0..3.0)]
p [kind("b", "a".."c"), kind("d", "a".."c"), kind(:b, "a".."c")]
p [kind("xab", /a/), kind(:ab, /a/), kind("x", /a/), kind(5, /a/), kind(nil, /a/)]
p [kind(2, Integer), kind(2, String), kind("s", String), kind(nil, NilClass), kind(2, Comparable), kind(:s, Object)]
p [kind(Pt.new(1), Pt), kind(Pt3.new(1), Pt), kind(Pt.new(1), Pt3), kind(Box.new, Tagged), kind(Pt, Class), kind(Pt, Pt)]
p [kind(7, ->(x) { x > 5 }), kind(3, ->(x) { x > 5 }), kind(7, proc { |x| x == 7 })]
# a plain value still compares by ==, a user class's == included
p [kind(2, 2), kind(2, 2.0), kind("ab", "ab"), kind(:a, :a), kind(nil, nil), kind([1, 2], [1, 2]), kind({ a: 1 }, { a: 1 })]
p [kind(Pt.new(1), Pt.new(1)), kind(Pt.new(1), Pt.new(2)), kind(2, "2"), kind(:a, "a")]
# a Range, a Regexp and a Class are no match for themselves
p [kind(1..3, 1..3), kind(/a/, /a/), kind(Integer, Integer)]

# as a value, and with no else
def pick(v, pat) = (case v when pat then 1 end)
p [pick(2, 1..3), pick(9, 1..3), pick("s", String), pick("s", Symbol)]

# a table of patterns
PATS = [1..3, /a/, String, 9, :q, nil].freeze
def first_hit(v)
  PATS.each_with_index do |pat, i|
    case v
    when pat then return i
    end
  end
  -1
end
p [first_hit(2), first_hit("xa"), first_hit("zz"), first_hit(9), first_hit(:q), first_hit(nil), first_hit(4.5)]

# a Hash's values, a block parameter, an instance variable, two patterns in one when
bands = { low: 1..3, high: 4..9 }
bands.each { |k, r| case 5 when r then p k end }
[1..3, 4..9].each { |r| case 5 when r then p r end }
class Rule
  def initialize(pat) = @pat = pat
  def match?(v) = (case v when @pat then true else false end)
end
p [Rule.new(1..3), Rule.new(/a/), Rule.new(Symbol)].map { |r| [r.match?(2), r.match?("a"), r.match?(:a)] }
a = PATS[0]
b = PATS[1]
p [9, "ya", 3, :ya].map { |v| case v when a, b then :either else :neither end }

# a Regexp held boxed sets the match, as one written in place does
re = [/(\d+)-(\d+)/, 1][0]
case "id 12-34"
when re then p [$1, $2, $~[0]]
end
