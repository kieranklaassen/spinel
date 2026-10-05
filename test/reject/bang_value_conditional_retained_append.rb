# The same value out of an arm of a conditional (`s.strip! || s` is the
# String either way in CRuby): appended to, it is refused as well.
s = +" ab "
r = s.strip! || s
r << " and a tail long enough to move the buffer"
p s, r
