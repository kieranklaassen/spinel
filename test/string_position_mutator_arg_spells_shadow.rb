# slice!, setbyte, insert, []= and clear on a shared String run against a
# shadow copy, the C locals lv__sb1 and lv__sb9 here. Statements an argument
# hoists that read the shadow send the arguments to be evaluated first; a
# String literal that only spells the shadow's name is no read, and the call
# is emitted as it was.

s = "qrst".dup
t = s
t[0, 0] = [1].map { |x| s << "y"; "lv__sb1" }.join
p s, t, s.equal?(t)

u = "qrst".dup
v = u
v[0, 1] = [1].map { |x| u << "y"; "'lv__sb9\\" }.join
p u, v, u.equal?(v)
