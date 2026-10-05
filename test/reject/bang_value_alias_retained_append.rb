# A local that is only ever another name for the kept value changes the
# same String: refused as a change through the kept value itself is.
s = +"abcd"
r = s.upcase!
t = r
t << " and a tail long enough to move the buffer"
p s, r
