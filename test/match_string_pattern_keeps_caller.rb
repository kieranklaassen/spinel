# A method whose match is `match` with a String pattern, or with a pattern
# that is a Regexp or a String only as the program runs, leaves its caller's
# match alone, as a method that matches a Regexp literal does.

def zero(s) = s.match("(0)")
def dash?(s, pat) = s.match(pat) ? true : false
def first_of(v, pat)
  m = v.match(pat)
  m ? m[0] : "none"
end
def own_then_none(s)
  before = $~.inspect
  s.match("z")
  before + " " + $&
end

"ab" =~ /(a)/
zero("x0")
p $1, $~[0]

line = "2026-10-05 x"
if line =~ /(\d+)-(\d+)/
  p dash?(line, "-")
  p $1, $2, $~.begin(2), $~.to_a
  p dash?(line, "q")
  p $1, $~.pre_match, $~.post_match
end

mixed = ["k7 z", :sym, 3]
pats = ["(z)", /(\d)/]
"left right" =~ /(l\w+) (r\w+)/
p first_of(mixed[0], pats[0]), $1, $2
p first_of(mixed[0], pats[1]), $~.to_a
p first_of("abc", pats[0]), Regexp.last_match(2)

"keep" =~ /(e+)/
p own_then_none("xyz"), $1, $`
