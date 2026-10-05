# s[re] = v and s[re, n] = v take a Regexp that is no literal the compiler can
# name -- held in a parameter, an instance variable or a global, answered by
# a call, or interpolated -- as they take the literal. They raised
# NoMethodError.
$g = /b(z)/
class Rule
  def initialize(re) = @re = re
  def put(s)
    s[@re] = "Q"
    s
  end
end
def put(s, re)
  s[re] = "Q"
  s
end
def put_n(s, re, n)
  s[re, n] = "Q"
  s
end
def made = /a/

p put("xaybzab".dup, /a/), put("xaybzab".dup, /b./)
p put_n("xaybzab".dup, /(a)(y)/, 2), put_n("xaybzab".dup, /(a)(y)/, 0)
rule = Rule.new(/y/)
p rule.put("yes".dup), rule.put("xaybzab".dup)
t = "xaybzab".dup
t[$g] = "1"
t[made] = "2"
t[$g, 0] = "3" if t =~ $g
p t
t = "xaybzab".dup
t[/#{"b"}z/] = "!"
p t
begin
  put("xaybzab".dup, /q/)
rescue IndexError => e
  puts "IndexError: #{e.message}"
end
begin
  put("xaybzab", /a/)
rescue FrozenError => e
  puts "FrozenError: #{e.message}"
end

# one never set is nil
re = /b/ if t.empty?
begin
  t[re] = "Q"
rescue TypeError => e
  puts "TypeError: #{e.message}"
end
p t
