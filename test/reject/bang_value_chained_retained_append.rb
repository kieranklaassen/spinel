# The value kept through a chained write is the same value: refused when
# it is then changed in place.
s = +"abcd"
r = t = s.upcase!
r << " and a tail long enough to move the buffer"
p s, t
