# slice!, setbyte, insert, []= and clear on a shared String run against a
# shadow copy, the C locals lv__sb1 and lv__sb9 here. An argument's hoisted
# statements that read the shadow run after it is declared; a String
# literal that only spells its name is no read, and they stay ahead of the
# statement.

s = "qrst".dup
t = s
t.insert(0, [1].map { |x| s << "y"; "lv__sb1" }.join)
p s, t, s.equal?(t)

u = "qrst".dup
v = u
v[0, 1] = [1].map { |x| u << "y"; "'lv__sb9\\" }.join
p u, v, u.equal?(v)
