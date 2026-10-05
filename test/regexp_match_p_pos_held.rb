# Regexp#match?(str, pos) takes a Regexp that is no literal the compiler can
# name -- held in a parameter, an instance variable or a global, answered by a
# call, or interpolated -- as it takes the literal. The call was refused at
# compile time (unsupported call).
$g = /a/
class Rule
  def initialize(re) = @re = re
  def from?(s, pos) = @re.match?(s, pos)
end
def from?(re, s, pos) = re.match?(s, pos)
def made = /z/

s = "xaybzab"
p from?(/b/, s, 0), from?(/b/, s, 4), from?(/b/, s, 6), from?(/b/, s, 7)
p from?(/B/i, s, 6), from?(/^x/, s, 1), from?(/b\z/, s, 6)
rule = Rule.new(/y/)
p rule.from?(s, 2), rule.from?(s, 3)
p $g.match?(s, 5), $g.match?(s, 6), made.match?(s, 4), made.match?(s, 5)
t = "y"
p (/a#{t}/).match?(s, 1), (/a#{t}/).match?(s, 2)

# it leaves $~ as it was
"q" =~ /q/
p from?(/b/, s, 0), $~[0]
