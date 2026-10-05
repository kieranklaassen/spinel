# The minimum of a String Range whose end is excluded is its begin, decided
# by the two ends alone as CRuby's range_min decides it: nil when the begin
# is past the end or at it, the begin otherwise. It walked the members for
# the least one, so ("9"..."11"), which holds "9" and "10" though "9" > "11",
# answered "10" where CRuby answers nil, ("11"..."9") answered nil for "11",
# and an endless ("a"...) raised. The maximum of such a range still walks.

p ("9"..."11").min
p ("11"..."9").min
p ("a"..."a").min
p ("a"..."c").min
p ("b"..."a").min
p ("a"...).min
p ("9"..."11").minmax
p ("a"..."c").minmax
p ("a"..."a").minmax
# a begin longer than the end: the walk holds nothing, the minimum is the begin
p ("aaa"..."zz").min
p ("aaa"..."zz").minmax
# a NUL is a byte like another: the ends are compared whole
p ("a"..."a\0").min
p ("a\0b"..."a\0c").min
p ("a\0c"..."a\0b").min
p ("a\0b".."a\0a").min

# the answer is a String of its own, as a member of the walk was
m = ("a".sub("x", "y")..."zz").min
p m.frozen?
m << "x"
p m

# the ends are compared by their bytes alone
ch = "\xbf".b.chars[0]
lit = "\xbf".b
p (ch..lit).min.nil?
p (lit..."\xff".b).min == ch

# a range held in a local, and one built from two locals
r = ("9"..."11")
p r.min
p r.max
lo = "11"
hi = "9"
p (lo...hi).min
p (lo..hi).min
p (hi...lo).min
p (hi...lo).max

# a range read out of a slot that holds other kinds too
def least(v) = v.min
p least(3..7)
p least("9"..."11")
p least("11"..."9")
p least("a"..."c")

# the open sides CRuby refuses stay refused
begin
  p (..."b").min
rescue RangeError => e
  puts e.message
end
begin
  p ("a"...).max
rescue RangeError => e
  puts e.message
end
