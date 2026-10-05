# any?, all?, none? and one? over an Array of Strings take a Regexp that is no
# literal the compiler can name -- held in a parameter, an instance variable or
# a global, answered by a call, or interpolated -- as they take the literal.
# It was compared with ==, so no element matched.
$g = /b/
class Rule
  def initialize(re) = @re = re
  def any(a) = a.any?(@re)
  def all(a) = a.all?(@re)
  def none(a) = a.none?(@re)
  def one(a) = a.one?(@re)
end
def by_param(a, re) = [a.any?(re), a.all?(re), a.none?(re), a.one?(re)]
def made = /^x/

a = ["xb", "q", "xbb"]
p by_param(a, /b/), by_param(a, /z/), by_param(a, /./), by_param(a, /q/)
p by_param([], /b/)
rule = Rule.new(/Q/i)
p rule.any(a), rule.all(a), rule.none(a), rule.one(a)
p a.any?($g), a.all?($g), a.none?($g), a.one?($g)
p a.any?(made), a.all?(made), a.none?(made), a.one?(made)
x = "b"
p a.any?(/#{x}b/), a.one?(/#{x}b/), a.all?(/#{x}|q/)

# one never set is nil, which no String is
re = /b/ if a.empty?
p a.any?(re), a.all?(re), a.none?(re), a.one?(re), [].all?(re)
