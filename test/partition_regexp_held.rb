# partition and rpartition take a Regexp that is no literal the compiler can
# name -- held in a parameter, an instance variable or a global, answered by
# a call, or interpolated -- as they take the literal. They raised TypeError
# (no implicit conversion of Regexp into String).
$g = /b./
class Rule
  def initialize(re) = @re = re
  def parts(s) = s.partition(@re)
end
def parts(s, re) = [s.partition(re), s.rpartition(re)]
def made = /a/

s = "xaybzab"
p parts(s, /a/), parts(s, /q/), parts(s, /(b)(z)/), parts("", /a/)
rule = Rule.new(/y/)
p rule.parts(s), rule.parts("no")
p s.partition($g), s.rpartition($g), s.partition(made), s.rpartition(made)
t = "x"
p s.partition(/#{t}a/), s.rpartition(/a#{"y"}/)
s.partition($g)
p $~[0], $`

# one never set is nil
re = /b/ if s.empty?
[-> { s.partition(re) }, -> { s.rpartition(re) }].each do |f|
  begin
    p f.call
  rescue TypeError => e
    puts "TypeError: #{e.message}"
  end
end
