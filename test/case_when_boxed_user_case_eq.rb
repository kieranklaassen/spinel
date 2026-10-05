# A `when` whose pattern is held boxed calls the pattern's own === when its
# class defines one or inherits one, alone, beside builtin patterns in a
# table, and in a `when *list`. Its == was asked instead, so an object that
# is a matcher never matched.
class Even
  def ===(o) = o.is_a?(Integer) && o.even?
end
class Longer
  def initialize(n) = @n = n
  def ===(o) = o.is_a?(String) && o.size > @n
end
class EvenToo < Even; end
class Plain; end

def kind(v, pat)
  case v
  when pat then :hit
  else :miss
  end
end
p [kind(4, Even.new), kind(5, Even.new), kind("4", Even.new), kind(4, EvenToo.new)]
p [kind("abc", Longer.new(2)), kind("ab", Longer.new(2)), kind(3, Longer.new(2))]
# an object with no === of its own matches itself alone
pl = Plain.new
p [kind(pl, pl), kind(Plain.new, pl), kind(4, pl)]

RULES = [Even.new, Longer.new(2), 1..3, /z/].freeze
def first_rule(v)
  RULES.each_with_index do |r, i|
    case v
    when r then return i
    end
  end
  -1
end
p [4, 3, "abc", "az", "ab", 7, :x].map { |v| first_rule(v) }
p [6, 7, "abcd", nil].map { |v| case v when *RULES then :in_list else :none end }
case "long enough"
when *RULES then p :statement_list
end
