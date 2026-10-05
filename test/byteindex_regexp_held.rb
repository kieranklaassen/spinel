# byteindex and byterindex take a Regexp that is no literal the compiler can
# name -- held in a parameter, an instance variable or a global, answered by
# a call, or interpolated -- as they take the literal. They raised
# NoMethodError.
$g = /b./
class Rule
  def initialize(re) = @re = re
  def at(s) = s.byteindex(@re)
end
def at(s, re) = [s.byteindex(re), s.byteindex(re, 3), s.byterindex(re), s.byterindex(re, 4)]
def made = /a/

s = "xaybzab"
p at(s, /a/), at(s, /b/), at(s, /q/), at("éab", /b/)
rule = Rule.new(/y/)
p rule.at(s), rule.at("no")
p s.byteindex($g), s.byterindex($g), s.byteindex(made), s.byterindex(made)
t = "x"
p s.byteindex(/#{t}a/), s.byterindex(/a#{"b"}/)

# one never set is nil, which is no String either
re = /b/ if s.empty?
[-> { s.byteindex(re) }, -> { s.byterindex(re) }].each do |f|
  begin
    p f.call
  rescue TypeError => e
    puts "TypeError: #{e.message}"
  end
end
