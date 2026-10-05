# A Regexp in a `when` that is no literal the compiler can name -- held in a
# global, an instance variable or a parameter, or answered by a call -- matches
# a String or a Symbol as the literal does. It was compared with ==, so it
# never matched. And beside a subject that is neither, a Regexp is no match:
# `case /a/ when /a/` took the arm.
$pat = /a(b)?/
class Rule
  def initialize(re) = @re = re
  def kind(v) = (case v when @re then :hit else :miss end)
  def show(v)
    case v
    when @re then puts "hit #{$~[0]}"
    else puts "miss"
    end
  end
end
def by_param(v, re) = (case v when :zz, re then :hit else :miss end)
$made = 0
def made
  $made += 1
  /b/
end

p(case "ab" when $pat then :hit else :miss end)
p(case "xy" when $pat then :hit else :miss end)
p(case :ab when $pat then :hit else :miss end)
p(case :xy when $pat then :hit else :miss end)
case "cab"
when $pat then p [:hit, $~[0], $1]
else p :miss
end
p(case "ab" when made then 1 end)
p(case "xy" when made then 1 end)
p $made

rule = Rule.new(/^a/)
p rule.kind("ab"), rule.kind("ba")
rule.show("abc")
rule.show("cba")
p by_param("ab", /b$/), by_param("ba", /b$/)

# a boxed subject: a String, a shared one, a Symbol, and what is neither
buf = +"a"
buf << "b"
["ab", buf, :ab, "xy", :xy, 2, nil, 2.5, ["ab"]].each do |v|
  print(case v when $pat then "h" else "-" end)
end
puts

# a subject that is neither a String nor a Symbol is no match
p(case /a/ when /a/ then :hit else :miss end)
p(case 2 when $pat then :hit else :miss end)
p(case 2.5 when /a/ then :hit else :miss end)
p(case true when $pat then :hit else :miss end)
p(case [1] when /a/ then :hit else :miss end)
p(case (1..3) when $pat then :hit else :miss end)
