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

# the Range out of a variable, an end that is nil at run time
r = (0..)
s = +"abc"; s[r] = "x"; p s
n = nil
s = +"abc"; s[0..n] = "x"; p s
def upto(k) = k == 0 ? nil : k
s = +"abc"; s[0..upto(0)] = "x"; p s
s = +"abc"; s[0..upto(1)] = "x"; p s
s = +"abc"; s[Range.new(0, nil)] = "x"; p s

# the value of the assignment, a second name, a method's parameter
s = +"abc"; t = s; v = (s[0..] = "x"); p v, s, t
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
# an end of 9223372036854775807 written in the index is not endless
s = +"abc"; s[0..9223372036854775807] = "x"; p s
