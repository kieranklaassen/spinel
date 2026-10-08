# Range#max with a count answers the n greatest members by <=>. A String
# Range walks its members by succ, which is that order only between ends
# of one length: ("9".."11") walks "9", "10", "11", and "9" is the
# greatest of them.
p ("9".."11").max(2)
p ("9".."11").max(1)
p ("9".."11").max(5)
p ("9".."11").max(0)
p ("9"..."11").max(2)
p ("8".."12").max(3)
p ("98".."102").max(2)
p ("a".."bb").max(3)
r = ("9".."11")
p r.max(2), r.to_a
lo = "9"
hi = "1" + "1"
p (lo..hi).max(2)
def top(r, n)
  r.max(n)
end
p top(("8".."12"), 2), top(("a".."c"), 2)
# min with a count is first(n): the walk's own order
p r.min(2)
# between ends of one length the walk is in order already
p ("a".."e").max(2), ("08".."11").max(2), ("az".."bc").max(3)
p ("b".."a").max(2)
