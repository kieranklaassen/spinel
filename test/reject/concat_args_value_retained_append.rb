# concat and prepend with other than one argument answer their receiver as
# the bang methods do, and no alias walk follows them: the kept value that
# is appended to is refused.
s = +"ab"
r = s.concat("c", "d")
r << " and a tail long enough to move the buffer"
p s, r
