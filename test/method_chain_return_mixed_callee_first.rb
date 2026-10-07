# The loop that binds parameters after the inference fixpoint had eight
# rounds, and a parameter's type goes down one call a round where each callee
# is defined before its caller. A method that returns an Integer on one path
# and the next method's value on the other had its type from the Integer when
# the rounds ran out: from 9 methods `v = ear1(e)` held 0 for the Array the
# last one fills. The loop goes on now in a program where a method has its
# return type from one value while another has none, while the rounds still
# move types.

# 12 methods, each callee defined before its caller: an Integer early, the call at the tail
def ear12(a) a << 2.5 end
def ear11(x) return 1 if x.size > 99; ear12(x) end
def ear10(x) return 1 if x.size > 99; ear11(x) end
def ear9(x) return 1 if x.size > 99; ear10(x) end
def ear8(x) return 1 if x.size > 99; ear9(x) end
def ear7(x) return 1 if x.size > 99; ear8(x) end
def ear6(x) return 1 if x.size > 99; ear7(x) end
def ear5(x) return 1 if x.size > 99; ear6(x) end
def ear4(x) return 1 if x.size > 99; ear5(x) end
def ear3(x) return 1 if x.size > 99; ear4(x) end
def ear2(x) return 1 if x.size > 99; ear3(x) end
def ear1(x) return 1 if x.size > 99; ear2(x) end
e = []
v = ear1(e)
p v, e, v.equal?(e)

# 9 methods, the first length that printed 0
def nin9(a) a << 2.5 end
def nin8(x) return 1 if x.size > 99; nin9(x) end
def nin7(x) return 1 if x.size > 99; nin8(x) end
def nin6(x) return 1 if x.size > 99; nin7(x) end
def nin5(x) return 1 if x.size > 99; nin6(x) end
def nin4(x) return 1 if x.size > 99; nin5(x) end
def nin3(x) return 1 if x.size > 99; nin4(x) end
def nin2(x) return 1 if x.size > 99; nin3(x) end
def nin1(x) return 1 if x.size > 99; nin2(x) end
n = []
u = nin1(n)
p u

# both values returned
def mix12(a) a << 2.5 end
def mix11(x) return 1 if x.size > 99; return mix12(x) end
def mix10(x) return 1 if x.size > 99; return mix11(x) end
def mix9(x) return 1 if x.size > 99; return mix10(x) end
def mix8(x) return 1 if x.size > 99; return mix9(x) end
def mix7(x) return 1 if x.size > 99; return mix8(x) end
def mix6(x) return 1 if x.size > 99; return mix7(x) end
def mix5(x) return 1 if x.size > 99; return mix6(x) end
def mix4(x) return 1 if x.size > 99; return mix5(x) end
def mix3(x) return 1 if x.size > 99; return mix4(x) end
def mix2(x) return 1 if x.size > 99; return mix3(x) end
def mix1(x) return 1 if x.size > 99; return mix2(x) end
m = []
w = mix1(m)
p w

# the Integer from `when` and from `rescue`
def cs12(a) a << 7 end
def cs11(x) case x.size when 99 then return 7 end; return cs12(x) end
def cs10(x) case x.size when 99 then return 7 end; return cs11(x) end
def cs9(x) case x.size when 99 then return 7 end; return cs10(x) end
def cs8(x) case x.size when 99 then return 7 end; return cs9(x) end
def cs7(x) case x.size when 99 then return 7 end; return cs8(x) end
def cs6(x) case x.size when 99 then return 7 end; return cs7(x) end
def cs5(x) case x.size when 99 then return 7 end; return cs6(x) end
def cs4(x) case x.size when 99 then return 7 end; return cs5(x) end
def cs3(x) case x.size when 99 then return 7 end; return cs4(x) end
def cs2(x) case x.size when 99 then return 7 end; return cs3(x) end
def cs1(x) case x.size when 99 then return 7 end; return cs2(x) end
c = []
d = cs1(c)
p d
def rs12(a) a << 7 end
def rs11(x) begin; x.size; rescue; return 7; end; return rs12(x) end
def rs10(x) begin; x.size; rescue; return 7; end; return rs11(x) end
def rs9(x) begin; x.size; rescue; return 7; end; return rs10(x) end
def rs8(x) begin; x.size; rescue; return 7; end; return rs9(x) end
def rs7(x) begin; x.size; rescue; return 7; end; return rs8(x) end
def rs6(x) begin; x.size; rescue; return 7; end; return rs7(x) end
def rs5(x) begin; x.size; rescue; return 7; end; return rs6(x) end
def rs4(x) begin; x.size; rescue; return 7; end; return rs5(x) end
def rs3(x) begin; x.size; rescue; return 7; end; return rs4(x) end
def rs2(x) begin; x.size; rescue; return 7; end; return rs3(x) end
def rs1(x) begin; x.size; rescue; return 7; end; return rs2(x) end
j = []
k = rs1(j)
p k

# a String early (printed the Array as a String)
def st12(a) a << 2.5 end
def st11(x) return "s" if x.size > 99; st12(x) end
def st10(x) return "s" if x.size > 99; st11(x) end
def st9(x) return "s" if x.size > 99; st10(x) end
def st8(x) return "s" if x.size > 99; st9(x) end
def st7(x) return "s" if x.size > 99; st8(x) end
def st6(x) return "s" if x.size > 99; st7(x) end
def st5(x) return "s" if x.size > 99; st6(x) end
def st4(x) return "s" if x.size > 99; st5(x) end
def st3(x) return "s" if x.size > 99; st4(x) end
def st2(x) return "s" if x.size > 99; st3(x) end
def st1(x) return "s" if x.size > 99; st2(x) end
s = []
t = st1(s)
p t

# a Float early (TypeError)
def fl12(a) a << :k end
def fl11(x) return 2.5 if x.size > 99; fl12(x) end
def fl10(x) return 2.5 if x.size > 99; fl11(x) end
def fl9(x) return 2.5 if x.size > 99; fl10(x) end
def fl8(x) return 2.5 if x.size > 99; fl9(x) end
def fl7(x) return 2.5 if x.size > 99; fl8(x) end
def fl6(x) return 2.5 if x.size > 99; fl7(x) end
def fl5(x) return 2.5 if x.size > 99; fl6(x) end
def fl4(x) return 2.5 if x.size > 99; fl5(x) end
def fl3(x) return 2.5 if x.size > 99; fl4(x) end
def fl2(x) return 2.5 if x.size > 99; fl3(x) end
def fl1(x) return 2.5 if x.size > 99; fl2(x) end
f = []
g = fl1(f)
p g

# right before: 8 methods, the parameter early, and nil early
def ok8(a) a << 2.5 end
def ok7(x) return 1 if x.size > 99; ok8(x) end
def ok6(x) return 1 if x.size > 99; ok7(x) end
def ok5(x) return 1 if x.size > 99; ok6(x) end
def ok4(x) return 1 if x.size > 99; ok5(x) end
def ok3(x) return 1 if x.size > 99; ok4(x) end
def ok2(x) return 1 if x.size > 99; ok3(x) end
def ok1(x) return 1 if x.size > 99; ok2(x) end
o = []
q = ok1(o)
p q
def pm12(a) a << 2.5 end
def pm11(x) return x if x.size > 99; pm12(x) end
def pm10(x) return x if x.size > 99; pm11(x) end
def pm9(x) return x if x.size > 99; pm10(x) end
def pm8(x) return x if x.size > 99; pm9(x) end
def pm7(x) return x if x.size > 99; pm8(x) end
def pm6(x) return x if x.size > 99; pm7(x) end
def pm5(x) return x if x.size > 99; pm6(x) end
def pm4(x) return x if x.size > 99; pm5(x) end
def pm3(x) return x if x.size > 99; pm4(x) end
def pm2(x) return x if x.size > 99; pm3(x) end
def pm1(x) return x if x.size > 99; pm2(x) end
l = []
h = pm1(l)
p h
def nl12(a) a << 2.5 end
def nl11(x) return nil if x.size > 99; nl12(x) end
def nl10(x) return nil if x.size > 99; nl11(x) end
def nl9(x) return nil if x.size > 99; nl10(x) end
def nl8(x) return nil if x.size > 99; nl9(x) end
def nl7(x) return nil if x.size > 99; nl8(x) end
def nl6(x) return nil if x.size > 99; nl7(x) end
def nl5(x) return nil if x.size > 99; nl6(x) end
def nl4(x) return nil if x.size > 99; nl5(x) end
def nl3(x) return nil if x.size > 99; nl4(x) end
def nl2(x) return nil if x.size > 99; nl3(x) end
def nl1(x) return nil if x.size > 99; nl2(x) end
y = []
z = nl1(y)
p z
