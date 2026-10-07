# s[/re/, n] = v stored where CRuby raises. A group the pattern has not read
# whatever span an earlier match left in the registers, a group that took no
# part in the match cut the String at -1, and a nil value stored "". Each
# raises now, in CRuby's order, and leaves the String as it was.
def try
  yield
rescue IndexError, TypeError, ArgumentError => e
  puts "#{e.class}: #{e.message}"
end

s = +"abc"
s << "defghijklmnop"

# a group that took no part in the match
try { s[/(x)?bc/, 1] = "XYZW" }
try { s[/(a)|(z)/, 2] = "XYZW" }
try { s[/(b(x)?)c/, 2] = "XYZW" }
p s

# a group the pattern has not: one past its last, any in a pattern without
# groups, and one an earlier, wider match had
try { s[/(b)c/, 2] = "XYZW" }
try { s[/bc/, 1] = "XYZW" }
"zzz" =~ /(z)(z)(z)/
try { s[/(b)c/, 3] = "XYZW" }
n = 4
try { s[/(b)(c)(d)/, n] = "XYZW" }
p s

# a nil value, after the group is found
v = "x"
v = nil if ARGV.size == 0
try { s[/(b)(cd)/, 2] = v }
try { s[/(x)?bc/, 1] = v }
try { s[/(b)c/, 2] = v }
p s

# a value that is no String by its type: the group is looked at first
a = [1, "x", nil]
w = a[ARGV.size + 1]
try { s[/(x)?bc/, 1] = w }
try { s[/(b)c/, 2] = nil }
try { s[/(x)?bc/, 1] = 5 }
p s

# the value is read before any of them
try { s[/(x)?bc/, 1] = (s << "!"; "v") }
p s

# a value that raises is heard first, whatever its kind
try { s[/(x)?bc/, 1] = Integer("q").to_s }
try { s[/(x)?bc/, 1] = Integer("q") }
try { s[/(b)c/, 2] = Integer("q") }
p s

# a value that freezes the receiver: the group is looked at first, and the
# frozen String raises last
t = +"abc"
t << "def"
try { t[/(x)?bc/, 1] = (t.freeze; "v") }
try { t[/(b)c/, 2] = (t.freeze; "v") }
try { t[/(q)r/, 1] = "v" }
p t.frozen?
begin
  t[/(b)c/, 1] = "v"
rescue FrozenError => e
  puts "FrozenError: #{e.message}"
end
p t

# the groups beside them still store: the last group, an empty group, the
# other arm of an alternation, group 0
s[/(b)(c)(d)/, n - 1] = "D"
p s
s[/b()c/, 1] = "-"
p s
s[/(z)|(b)/, 2] = "B"
p s
s[/-cD/, 0] = "cd"
p s
v = "V"
s[/(a)(B)/, 2] = v
p s

# an instance variable and a parameter
class Line
  def initialize
    @s = +"key="
    @s << "value"
  end

  def set(n, v)
    @s[/(=)(\d)?(\w+)/, n] = v
    @s
  end
end
l = Line.new
try { p l.set(2, "x") }
try { p l.set(4, "x") }
try { p l.set(3, nil) }
try { p l.set(3, "v") }

def cut(s, n)
  s[/(b)(x)?c/, n] = "-"
  s
end
u = +"ab"
u << "cdef"
try { p cut(u, 2) }
try { p cut(u, 3) }
try { p cut(u, 1) }
