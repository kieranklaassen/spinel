# A `when` whose pattern is held boxed calls the pattern's own === when its
# class defines one or inherits one, alone and beside builtin patterns in a
# table. Its == was asked instead, so an object that is a matcher never
# matched.
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

# a block parameter, a Hash value, and a method that takes a String
class Prefix
  attr_accessor :s
  def initialize(s) = @s = s
  def ===(o) = o.to_s.start_with?(@s)
end
[Even.new, Prefix.new("ab")].each do |pat|
  case "abc"
  when pat then puts "block: #{pat.class}"
  end
end
by_name = { even: Even.new, ab: Prefix.new("ab") }
p(case 10 when by_name[:even] then :even else :odd end)
p [:abc, "xab", 12].map { |v| case v when by_name[:ab] then :ab else :other end }

# a matcher that is a method's value, with a === that allocates: the
# pattern and the subject are held across the call
class Has
  attr_accessor :s
  def initialize(s) = @s = s
  def ===(o)
    junk = []
    50.times { |i| junk << "x#{i}" }
    o.to_s.include?(@s)
  end
end
def has(i) = [Has.new("b" + "c"), :zz][i]
p [case "abcd" when has(0) then :hit else :miss end, case "abd" when has(0) then :hit else :miss end]
[1.5, "zbc", nil].each { |v| p(case v when has(1), has(0) then :hit else :miss end) }
