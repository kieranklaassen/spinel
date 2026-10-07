# slice!(re, n) takes every group number CRuby takes: a negative one counts
# back from the last group, and the tenth and beyond are groups like the rest
s = +"hello"
p s.slice!(/(e)(l)(l)/, -1), s
s = +"hello"
p s.slice!(/(e)(l)(l)/, -3), s
s = +"hello"
p s.slice!(/(e)(l)(l)/, -4), s

def cut(n)
  s = +"key=val;"
  r = s.slice!(/(\w+)(=)(\w+)/, n)
  [n, r, s, $~ && $~[0]]
end
[-5, -4, -3, -2, -1, 0, 1, 2, 3, 4].each { |n| p cut(n) }

w = +"abcdefghijklm"
p w.slice!(/(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)/, 10), w
p w.slice!(/(a)(b)(c)(d)(e)(f)(g)(h)(i)(k)(l)/, 11), w
w = +"abcdefghijklm"
p w.slice!(/(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)/, 13), w
p w.slice!(/(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)/, -1), w
p w.slice!(/(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)/, -11), w

# a tenth group that took no part, and bytes of more than one character
v = +"abcdefghi-"
p v.slice!(/(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)?-/, 9), v
u = +"äöü-ÄÖÜ-ßé-x"
i = 12
p u.slice!(/(ä)(ö)(ü)(-)(Ä)(Ö)(Ü)(-)(ß)(é)(-)(x)/, i), u
p u.slice!(/(ä)(ö)(ü)(-)(Ä)(Ö)(Ü)(-)(ß)(é)/, i - 2), u

# a frozen receiver raises whatever the number
begin
  "abc".slice!(/(b)/, -1)
rescue FrozenError => e
  p e.class
end
