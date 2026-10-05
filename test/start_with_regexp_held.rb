# start_with? takes a Regexp that is no literal the compiler can name -- held
# in a parameter, an instance variable or a global, answered by a call, or
# interpolated -- as it takes the literal. It raised TypeError (no implicit
# conversion of Regexp into String).
$g = /x./
class Rule
  def initialize(re) = @re = re
  def starts(s) = s.start_with?(@re)
end
def starts(s, re) = s.start_with?(re)
def made = /a/

s = "xaybzab"
p starts(s, /x/), starts(s, /a/), starts("", /x*/), starts(s, /X/i), starts(s, /^a|x/)
rule = Rule.new(/y/)
p rule.starts(s), rule.starts("yes")
p s.start_with?($g), s.start_with?(made), "abc".start_with?(made)
t = "x"
p s.start_with?(/#{t}a/), s.start_with?(/#{t}b/)
if s.start_with?($g)
  p $~[0], $~.post_match
end

# one never set is nil, which is no String either
re = /b/ if s.empty?
begin
  p s.start_with?(re)
rescue TypeError => e
  puts "TypeError: #{e.message}"
end
