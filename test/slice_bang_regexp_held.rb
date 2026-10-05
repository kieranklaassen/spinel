# slice! takes a Regexp that is no literal the compiler can name -- held in a
# parameter, an instance variable or a global, answered by a call, or
# interpolated -- alone or with a group, as it takes the literal. It raised
# NoMethodError.
$g = /b(z)/
class Rule
  def initialize(re) = @re = re
  def cut(s) = s.slice!(@re)
end
def cut(s, re)
  got = s.slice!(re)
  [got, s]
end
def cut_n(s, re, n)
  got = s.slice!(re, n)
  [got, s]
end
def made = /a/

p cut("xaybzab".dup, /a/), cut("xaybzab".dup, /q/), cut("xaybzab".dup, /b(z)?/)
p cut_n("xaybzab".dup, /(a)(y)/, 2), cut_n("xaybzab".dup, /(a)(y)/, 0)
p cut_n("xaybzab".dup, /(a)(y)/, 3), cut_n("xaybzab".dup, /q/, 0)
rule = Rule.new(/y/)
t = "xaybzab".dup
p rule.cut(t)
p t
t = "xaybzab".dup
p t.slice!($g)
p t.slice!(made)
p t
x = "y"
t = "xaybzab".dup
p t.slice!(/a#{x}/)
p t
begin
  cut("xaybzab", /a/)
rescue FrozenError => e
  puts "FrozenError: #{e.message}"
end

# one never set is nil
re = /b/ if t.empty?
begin
  p t.slice!(re)
rescue TypeError => e
  puts "TypeError: #{e.message}"
end
p t
