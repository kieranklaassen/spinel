# After the inference fixpoint an empty Array takes its kind from the method
# that fills it, and the kind comes back up as each method's return type,
# one method a round, in a loop of eight rounds. A chain of methods each
# handing its callee's value up as `r = f(x); return r` ran out of rounds:
# from 16 methods the first of them had no return type and compiled to a
# void function. `p up1(x)` printed nil for the Array the last one fills,
# and the empty Hash below crashed the program. The loop goes on now while
# a `return` waits for its type and the rounds still move types.

# 40 methods: the Array filled at the far end comes back the same Array
def up1(x) r = up2(x); return r end
def up2(x) r = up3(x); return r end
def up3(x) r = up4(x); return r end
def up4(x) r = up5(x); return r end
def up5(x) r = up6(x); return r end
def up6(x) r = up7(x); return r end
def up7(x) r = up8(x); return r end
def up8(x) r = up9(x); return r end
def up9(x) r = up10(x); return r end
def up10(x) r = up11(x); return r end
def up11(x) r = up12(x); return r end
def up12(x) r = up13(x); return r end
def up13(x) r = up14(x); return r end
def up14(x) r = up15(x); return r end
def up15(x) r = up16(x); return r end
def up16(x) r = up17(x); return r end
def up17(x) r = up18(x); return r end
def up18(x) r = up19(x); return r end
def up19(x) r = up20(x); return r end
def up20(x) r = up21(x); return r end
def up21(x) r = up22(x); return r end
def up22(x) r = up23(x); return r end
def up23(x) r = up24(x); return r end
def up24(x) r = up25(x); return r end
def up25(x) r = up26(x); return r end
def up26(x) r = up27(x); return r end
def up27(x) r = up28(x); return r end
def up28(x) r = up29(x); return r end
def up29(x) r = up30(x); return r end
def up30(x) r = up31(x); return r end
def up31(x) r = up32(x); return r end
def up32(x) r = up33(x); return r end
def up33(x) r = up34(x); return r end
def up34(x) r = up35(x); return r end
def up35(x) r = up36(x); return r end
def up36(x) r = up37(x); return r end
def up37(x) r = up38(x); return r end
def up38(x) r = up39(x); return r end
def up39(x) r = up40(x); return r end
def up40(a) a << 2.5 end
x = []
r = up1(x)
p r, x, r.equal?(x)

# 16 methods, the first length that printed nil
def six1(x) r = six2(x); return r end
def six2(x) r = six3(x); return r end
def six3(x) r = six4(x); return r end
def six4(x) r = six5(x); return r end
def six5(x) r = six6(x); return r end
def six6(x) r = six7(x); return r end
def six7(x) r = six8(x); return r end
def six8(x) r = six9(x); return r end
def six9(x) r = six10(x); return r end
def six10(x) r = six11(x); return r end
def six11(x) r = six12(x); return r end
def six12(x) r = six13(x); return r end
def six13(x) r = six14(x); return r end
def six14(x) r = six15(x); return r end
def six15(x) r = six16(x); return r end
def six16(a) a << 2.5 end
s = []
p six1(s)

# the far end returns explicitly, and the value is appended to (the C did not build)
def far1(x) r = far2(x); return r end
def far2(x) r = far3(x); return r end
def far3(x) r = far4(x); return r end
def far4(x) r = far5(x); return r end
def far5(x) r = far6(x); return r end
def far6(x) r = far7(x); return r end
def far7(x) r = far8(x); return r end
def far8(x) r = far9(x); return r end
def far9(x) r = far10(x); return r end
def far10(x) r = far11(x); return r end
def far11(x) r = far12(x); return r end
def far12(x) r = far13(x); return r end
def far13(x) r = far14(x); return r end
def far14(x) r = far15(x); return r end
def far15(x) r = far16(x); return r end
def far16(x) r = far17(x); return r end
def far17(x) r = far18(x); return r end
def far18(x) r = far19(x); return r end
def far19(x) r = far20(x); return r end
def far20(a) a << "s"; return a end
y = []
q = far1(y)
q << q[0]
p y

# two returns of the local
def two1(x) r = two2(x); return r if x.size > 99; return r end
def two2(x) r = two3(x); return r if x.size > 99; return r end
def two3(x) r = two4(x); return r if x.size > 99; return r end
def two4(x) r = two5(x); return r if x.size > 99; return r end
def two5(x) r = two6(x); return r if x.size > 99; return r end
def two6(x) r = two7(x); return r if x.size > 99; return r end
def two7(x) r = two8(x); return r if x.size > 99; return r end
def two8(x) r = two9(x); return r if x.size > 99; return r end
def two9(x) r = two10(x); return r if x.size > 99; return r end
def two10(x) r = two11(x); return r if x.size > 99; return r end
def two11(x) r = two12(x); return r if x.size > 99; return r end
def two12(x) r = two13(x); return r if x.size > 99; return r end
def two13(x) r = two14(x); return r if x.size > 99; return r end
def two14(x) r = two15(x); return r if x.size > 99; return r end
def two15(x) r = two16(x); return r if x.size > 99; return r end
def two16(x) r = two17(x); return r if x.size > 99; return r end
def two17(x) r = two18(x); return r if x.size > 99; return r end
def two18(x) r = two19(x); return r if x.size > 99; return r end
def two19(x) r = two20(x); return r if x.size > 99; return r end
def two20(a) a << 7 end
t = []
two1(t).each { |e| p e }
puts "#{two1(t)}"

# the local copied on before it is returned
def cp1(x) r = cp2(x); q = r; return q end
def cp2(x) r = cp3(x); q = r; return q end
def cp3(x) r = cp4(x); q = r; return q end
def cp4(x) r = cp5(x); q = r; return q end
def cp5(x) r = cp6(x); q = r; return q end
def cp6(x) r = cp7(x); q = r; return q end
def cp7(x) r = cp8(x); q = r; return q end
def cp8(x) r = cp9(x); q = r; return q end
def cp9(x) r = cp10(x); q = r; return q end
def cp10(x) r = cp11(x); q = r; return q end
def cp11(x) r = cp12(x); q = r; return q end
def cp12(x) r = cp13(x); q = r; return q end
def cp13(x) r = cp14(x); q = r; return q end
def cp14(x) r = cp15(x); q = r; return q end
def cp15(x) r = cp16(x); q = r; return q end
def cp16(x) r = cp17(x); q = r; return q end
def cp17(x) r = cp18(x); q = r; return q end
def cp18(x) r = cp19(x); q = r; return q end
def cp19(x) r = cp20(x); q = r; return q end
def cp20(a) a << :k end
c = []
p cp1(c)

# an empty Hash filled at the far end
def hs1(x) r = hs2(x); return r end
def hs2(x) r = hs3(x); return r end
def hs3(x) r = hs4(x); return r end
def hs4(x) r = hs5(x); return r end
def hs5(x) r = hs6(x); return r end
def hs6(x) r = hs7(x); return r end
def hs7(x) r = hs8(x); return r end
def hs8(x) r = hs9(x); return r end
def hs9(x) r = hs10(x); return r end
def hs10(x) r = hs11(x); return r end
def hs11(x) r = hs12(x); return r end
def hs12(x) r = hs13(x); return r end
def hs13(x) r = hs14(x); return r end
def hs14(x) r = hs15(x); return r end
def hs15(x) r = hs16(x); return r end
def hs16(x) r = hs17(x); return r end
def hs17(x) r = hs18(x); return r end
def hs18(x) r = hs19(x); return r end
def hs19(x) r = hs20(x); return r end
def hs20(a) a["k"] = "v"; a end
h = {}
g = hs1(h)
p g["k"], g.size, h.size

# instance methods
class Walk
  def w1(x) r = w2(x); return r end
  def w2(x) r = w3(x); return r end
  def w3(x) r = w4(x); return r end
  def w4(x) r = w5(x); return r end
  def w5(x) r = w6(x); return r end
  def w6(x) r = w7(x); return r end
  def w7(x) r = w8(x); return r end
  def w8(x) r = w9(x); return r end
  def w9(x) r = w10(x); return r end
  def w10(x) r = w11(x); return r end
  def w11(x) r = w12(x); return r end
  def w12(x) r = w13(x); return r end
  def w13(x) r = w14(x); return r end
  def w14(x) r = w15(x); return r end
  def w15(x) r = w16(x); return r end
  def w16(x) r = w17(x); return r end
  def w17(x) r = w18(x); return r end
  def w18(x) r = w19(x); return r end
  def w19(x) r = w20(x); return r end
  def w20(a) a << 2.5 end
end
w = []
p Walk.new.w1(w)

# right before: 15 methods, and 20 that end in the local with no `return`
def ok1(x) r = ok2(x); return r end
def ok2(x) r = ok3(x); return r end
def ok3(x) r = ok4(x); return r end
def ok4(x) r = ok5(x); return r end
def ok5(x) r = ok6(x); return r end
def ok6(x) r = ok7(x); return r end
def ok7(x) r = ok8(x); return r end
def ok8(x) r = ok9(x); return r end
def ok9(x) r = ok10(x); return r end
def ok10(x) r = ok11(x); return r end
def ok11(x) r = ok12(x); return r end
def ok12(x) r = ok13(x); return r end
def ok13(x) r = ok14(x); return r end
def ok14(x) r = ok15(x); return r end
def ok15(a) a << 2.5 end
o = []
p ok1(o)
def tl1(x) r = tl2(x); r end
def tl2(x) r = tl3(x); r end
def tl3(x) r = tl4(x); r end
def tl4(x) r = tl5(x); r end
def tl5(x) r = tl6(x); r end
def tl6(x) r = tl7(x); r end
def tl7(x) r = tl8(x); r end
def tl8(x) r = tl9(x); r end
def tl9(x) r = tl10(x); r end
def tl10(x) r = tl11(x); r end
def tl11(x) r = tl12(x); r end
def tl12(x) r = tl13(x); r end
def tl13(x) r = tl14(x); r end
def tl14(x) r = tl15(x); r end
def tl15(x) r = tl16(x); r end
def tl16(x) r = tl17(x); r end
def tl17(x) r = tl18(x); r end
def tl18(x) r = tl19(x); r end
def tl19(x) r = tl20(x); r end
def tl20(a) a << 2.5 end
l = []
p tl1(l)
