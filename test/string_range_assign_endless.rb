# spinel: int64
# String#[]= with an endless Range that starts at the String's first
# character replaces all of it: the count of characters ran over, and the
# String was kept behind the value.

s = +"abc"; s[0..] = "x"; p s
s = +"abc"; s[-3..] = "x"; p s
s = +"abc"; s[0..nil] = "x"; p s
s = +"abc"; s[nil..nil] = "x"; p s
s = +"héllo"; s[0..] = "x"; p s
s = +"abc"; s[0..] = ""; p s
s = +"abc"; s[(0..)] = "xyz" * 3; p s

# an end that is nil when the program runs
n = nil
s = +"abc"; s[0..n] = "x"; p s
def upto(k) = k == 0 ? nil : k
s = +"abc"; s[0..upto(0)] = "x"; p s
s = +"abc"; s[0..upto(1)] = "x"; p s
ends = [nil, 1]
s = +"abc"; s[0..ends[0]] = "x"; p s
s = +"abc"; s[0..ends[1]] = "x"; p s

# both ends run, the start first
def say(k, v) = (puts k; v)
s = +"abc"; s[say("start", 0)..say("end", nil)] = "x"; p s
s = +"abc"; s[say("start", 0)..upto(say("end", 0))] = "x"; p s

# the value of the assignment, a second name, a method's parameter
w = +"abc"; t = w; v = (w[0..] = "x"); p v, w, t
w = +"abc"; t = w; w[-3..nil] = "y"; p w, t
def from(s, i) = (s[i..] = "!"; s)
p from(+"abc", 0), from(+"abc", 2), from(+"abc", -3)

# as before: other starts, an excluded end, an end that is written
s = +"abc"; s[1..] = "x"; p s
s = +"abc"; s[3..] = "x"; p s
s = +"abc"; s[0...] = "x"; p s
s = +"abc"; s[..1] = "x"; p s
s = +"abc"; s[0..-1] = "x"; p s
s = +""; s[0..] = "x"; p s
e = 2
s = +"abc"; s[0..e] = "x"; p s

# An end of 9223372036854775807 is not "no end": from the first character
# the count runs over in CRuby too, and nothing is replaced. Written in the
# index, as it is or as a value that could have been nil:
big = 9223372036854775807
z = 0
s = +"abcdef"; s[0..9223372036854775807] = "x"; p s
s = +"abcdef"; s[-6..9223372036854775807] = "x"; p s
s = +"abcdef"; s[0..big] = "x"; p s
s = +"abcdef"; s[z..big] = "x"; p s
def top(k) = k == 0 ? nil : 9223372036854775807
bigm = top(1)
s = +"abcdef"; s[0..bigm] = "x"; p s
s = +"abcdef"; s[(0..bigm)] = "x"; p s
s = +"abcdef"; s[-6..bigm] = "x"; p s
s = +"abcdef"; s[z..bigm] = "x"; p s
s = +"abcdef"; s[1..bigm] = "x"; p s
s = +"abcdef"; s[0...bigm] = "x"; p s
s = +"abcdef"; s[0..top(1)] = "x"; p s
s = +"abcdef"; s[0..top(0)] = "x"; p s
s = +"abcdef"; v = (s[0..bigm] = "x"); p v, s
tops = [nil, 9223372036854775807]
s = +"abcdef"; s[0..tops[1]] = "x"; p s
s = +"abcdef"; s[0..tops[0]] = "x"; p s
class Line
  def initialize; @s = +"abcdef"; end
  def cut(m) = (@s[0..m] = "x"; @s)
end
p Line.new.cut(top(1)), Line.new.cut(top(0))
def cut(s, m) = (s[0..m] = "x"; s)
p cut(+"abcdef", top(1)), cut(+"abcdef", top(0))
# and as a Range out of a variable, a method or a constant
r = (0..9223372036854775807)
s = +"abcdef"; s[r] = "x"; p s
r = (0..big)
s = +"abcdef"; s[r] = "x"; p s
r = (z..big)
s = +"abcdef"; s[r] = "x"; p s
r = (-6..big)
s = +"abcdef"; s[r] = "x"; p s
def whole = (0..9223372036854775807)
s = +"abcdef"; s[whole] = "x"; p s
def whole_to(b) = (0..b)
s = +"abcdef"; s[whole_to(big)] = "x"; p s
WHOLE = (0..9223372036854775807)
s = +"abcdef"; s[WHOLE] = "x"; p s
s = +"abcdef"; v = (s[r] = "x"); p v, s
def put(s, r) = (s[r] = "x"; s)
p put(+"abcdef", (0..big)), put(+"abcdef", (1..big))
