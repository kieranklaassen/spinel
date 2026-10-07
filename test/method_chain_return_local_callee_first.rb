# A parameter's type goes down one call a round where each callee is defined
# before its caller, and the loop that binds parameters after the inference
# fixpoint had eight rounds. An empty Array handed down such a chain, each
# method answering `r = f(x); return r`, ran out of them: from 9 methods the
# first had no return type, and `p dn1(x)` printed nil for the Array the last
# one fills. The loop goes on now in a program where a `return` hands back a
# local that has no type, while the rounds still move types.

# 30 methods, each callee defined before its caller
def dn30(a) a << 2.5 end
def dn29(x) r = dn30(x); return r end
def dn28(x) r = dn29(x); return r end
def dn27(x) r = dn28(x); return r end
def dn26(x) r = dn27(x); return r end
def dn25(x) r = dn26(x); return r end
def dn24(x) r = dn25(x); return r end
def dn23(x) r = dn24(x); return r end
def dn22(x) r = dn23(x); return r end
def dn21(x) r = dn22(x); return r end
def dn20(x) r = dn21(x); return r end
def dn19(x) r = dn20(x); return r end
def dn18(x) r = dn19(x); return r end
def dn17(x) r = dn18(x); return r end
def dn16(x) r = dn17(x); return r end
def dn15(x) r = dn16(x); return r end
def dn14(x) r = dn15(x); return r end
def dn13(x) r = dn14(x); return r end
def dn12(x) r = dn13(x); return r end
def dn11(x) r = dn12(x); return r end
def dn10(x) r = dn11(x); return r end
def dn9(x) r = dn10(x); return r end
def dn8(x) r = dn9(x); return r end
def dn7(x) r = dn8(x); return r end
def dn6(x) r = dn7(x); return r end
def dn5(x) r = dn6(x); return r end
def dn4(x) r = dn5(x); return r end
def dn3(x) r = dn4(x); return r end
def dn2(x) r = dn3(x); return r end
def dn1(x) r = dn2(x); return r end
x = []
r = dn1(x)
p r, x, r.equal?(x)

# 9 methods, the first length that printed nil
def nine9(a) a << 2.5 end
def nine8(x) r = nine9(x); return r end
def nine7(x) r = nine8(x); return r end
def nine6(x) r = nine7(x); return r end
def nine5(x) r = nine6(x); return r end
def nine4(x) r = nine5(x); return r end
def nine3(x) r = nine4(x); return r end
def nine2(x) r = nine3(x); return r end
def nine1(x) r = nine2(x); return r end
s = []
p nine1(s)

# the value is appended to (the C did not build)
def app12(a) a << "s" end
def app11(x) r = app12(x); return r end
def app10(x) r = app11(x); return r end
def app9(x) r = app10(x); return r end
def app8(x) r = app9(x); return r end
def app7(x) r = app8(x); return r end
def app6(x) r = app7(x); return r end
def app5(x) r = app6(x); return r end
def app4(x) r = app5(x); return r end
def app3(x) r = app4(x); return r end
def app2(x) r = app3(x); return r end
def app1(x) r = app2(x); return r end
y = []
q = app1(y)
q << q[0]
p y

# two returns of the local, and the value iterated (NoMethodError)
def two12(a) a << 7 end
def two11(x) r = two12(x); return r if x.size > 99; return r end
def two10(x) r = two11(x); return r if x.size > 99; return r end
def two9(x) r = two10(x); return r if x.size > 99; return r end
def two8(x) r = two9(x); return r if x.size > 99; return r end
def two7(x) r = two8(x); return r if x.size > 99; return r end
def two6(x) r = two7(x); return r if x.size > 99; return r end
def two5(x) r = two6(x); return r if x.size > 99; return r end
def two4(x) r = two5(x); return r if x.size > 99; return r end
def two3(x) r = two4(x); return r if x.size > 99; return r end
def two2(x) r = two3(x); return r if x.size > 99; return r end
def two1(x) r = two2(x); return r if x.size > 99; return r end
t = []
two1(t).each { |e| p e }

# an empty Hash filled at the far end
def hs12(a) a["k"] = "v"; a end
def hs11(x) r = hs12(x); return r end
def hs10(x) r = hs11(x); return r end
def hs9(x) r = hs10(x); return r end
def hs8(x) r = hs9(x); return r end
def hs7(x) r = hs8(x); return r end
def hs6(x) r = hs7(x); return r end
def hs5(x) r = hs6(x); return r end
def hs4(x) r = hs5(x); return r end
def hs3(x) r = hs4(x); return r end
def hs2(x) r = hs3(x); return r end
def hs1(x) r = hs2(x); return r end
h = {}
g = hs1(h)
p g["k"], g.size, h.size

# right before: 8 methods, and 12 that end in the local with no `return`
def ok8(a) a << 2.5 end
def ok7(x) r = ok8(x); return r end
def ok6(x) r = ok7(x); return r end
def ok5(x) r = ok6(x); return r end
def ok4(x) r = ok5(x); return r end
def ok3(x) r = ok4(x); return r end
def ok2(x) r = ok3(x); return r end
def ok1(x) r = ok2(x); return r end
o = []
p ok1(o)
def tl12(a) a << 2.5 end
def tl11(x) r = tl12(x); r end
def tl10(x) r = tl11(x); r end
def tl9(x) r = tl10(x); r end
def tl8(x) r = tl9(x); r end
def tl7(x) r = tl8(x); r end
def tl6(x) r = tl7(x); r end
def tl5(x) r = tl6(x); r end
def tl4(x) r = tl5(x); r end
def tl3(x) r = tl4(x); r end
def tl2(x) r = tl3(x); r end
def tl1(x) r = tl2(x); r end
l = []
p tl1(l)
