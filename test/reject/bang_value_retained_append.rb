# The value of a String method that changes its receiver and answers it (or
# nil when nothing changed), kept in a local that is then changed in place,
# is not yet the receiver's own String: refused, not silently changed in a
# copy.
title = +"abcd"
label = title.upcase!
label << " and a tail long enough to move the buffer"
t = +" ab "
u = t.strip!
u.concat(" and a tail long enough to move the buffer") if u
g = +"abcab"
w = g.gsub!("b", "x")
w.insert(0, " and a tail long enough to move the buffer") if w
p title, label, t, u, g, w
