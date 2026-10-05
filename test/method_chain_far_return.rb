# The last lift of a return type reads a method's tail value, and a method
# that ends in `return f(x)` has none. A chain of 32 such methods handing
# an empty Array down to the one that appends to it left the first without
# a type: `q = rt1(y)` was nil, with nothing said. A method whose every
# return is a call on self takes the type those calls answer.

# 45 methods, each returning the next one's value; the last appends
def rt1(x)
  return rt2(x)
end
def rt2(x)
  return rt3(x)
end
def rt3(x)
  return rt4(x)
end
def rt4(x)
  return rt5(x)
end
def rt5(x)
  return rt6(x)
end
def rt6(x)
  return rt7(x)
end
def rt7(x)
  return rt8(x)
end
def rt8(x)
  return rt9(x)
end
def rt9(x)
  return rt10(x)
end
def rt10(x)
  return rt11(x)
end
def rt11(x)
  return rt12(x)
end
def rt12(x)
  return rt13(x)
end
def rt13(x)
  return rt14(x)
end
def rt14(x)
  return rt15(x)
end
def rt15(x)
  return rt16(x)
end
def rt16(x)
  return rt17(x)
end
def rt17(x)
  return rt18(x)
end
def rt18(x)
  return rt19(x)
end
def rt19(x)
  return rt20(x)
end
def rt20(x)
  return rt21(x)
end
def rt21(x)
  return rt22(x)
end
def rt22(x)
  return rt23(x)
end
def rt23(x)
  return rt24(x)
end
def rt24(x)
  return rt25(x)
end
def rt25(x)
  return rt26(x)
end
def rt26(x)
  return rt27(x)
end
def rt27(x)
  return rt28(x)
end
def rt28(x)
  return rt29(x)
end
def rt29(x)
  return rt30(x)
end
def rt30(x)
  return rt31(x)
end
def rt31(x)
  return rt32(x)
end
def rt32(x)
  return rt33(x)
end
def rt33(x)
  return rt34(x)
end
def rt34(x)
  return rt35(x)
end
def rt35(x)
  return rt36(x)
end
def rt36(x)
  return rt37(x)
end
def rt37(x)
  return rt38(x)
end
def rt38(x)
  return rt39(x)
end
def rt39(x)
  return rt40(x)
end
def rt40(x)
  return rt41(x)
end
def rt41(x)
  return rt42(x)
end
def rt42(x)
  return rt43(x)
end
def rt43(x)
  return rt44(x)
end
def rt44(x)
  return rt45(x)
end
def rt45(a) = a << "s"

# two returns in each
def tw1(x)
  return tw2(x) if x.size > 99
  return tw2(x)
end
def tw2(x)
  return tw3(x) if x.size > 99
  return tw3(x)
end
def tw3(x)
  return tw4(x) if x.size > 99
  return tw4(x)
end
def tw4(x)
  return tw5(x) if x.size > 99
  return tw5(x)
end
def tw5(x)
  return tw6(x) if x.size > 99
  return tw6(x)
end
def tw6(x)
  return tw7(x) if x.size > 99
  return tw7(x)
end
def tw7(x)
  return tw8(x) if x.size > 99
  return tw8(x)
end
def tw8(x)
  return tw9(x) if x.size > 99
  return tw9(x)
end
def tw9(x)
  return tw10(x) if x.size > 99
  return tw10(x)
end
def tw10(x)
  return tw11(x) if x.size > 99
  return tw11(x)
end
def tw11(x)
  return tw12(x) if x.size > 99
  return tw12(x)
end
def tw12(x)
  return tw13(x) if x.size > 99
  return tw13(x)
end
def tw13(x)
  return tw14(x) if x.size > 99
  return tw14(x)
end
def tw14(x)
  return tw15(x) if x.size > 99
  return tw15(x)
end
def tw15(x)
  return tw16(x) if x.size > 99
  return tw16(x)
end
def tw16(x)
  return tw17(x) if x.size > 99
  return tw17(x)
end
def tw17(x)
  return tw18(x) if x.size > 99
  return tw18(x)
end
def tw18(x)
  return tw19(x) if x.size > 99
  return tw19(x)
end
def tw19(x)
  return tw20(x) if x.size > 99
  return tw20(x)
end
def tw20(x)
  return tw21(x) if x.size > 99
  return tw21(x)
end
def tw21(x)
  return tw22(x) if x.size > 99
  return tw22(x)
end
def tw22(x)
  return tw23(x) if x.size > 99
  return tw23(x)
end
def tw23(x)
  return tw24(x) if x.size > 99
  return tw24(x)
end
def tw24(x)
  return tw25(x) if x.size > 99
  return tw25(x)
end
def tw25(x)
  return tw26(x) if x.size > 99
  return tw26(x)
end
def tw26(x)
  return tw27(x) if x.size > 99
  return tw27(x)
end
def tw27(x)
  return tw28(x) if x.size > 99
  return tw28(x)
end
def tw28(x)
  return tw29(x) if x.size > 99
  return tw29(x)
end
def tw29(x)
  return tw30(x) if x.size > 99
  return tw30(x)
end
def tw30(x)
  return tw31(x) if x.size > 99
  return tw31(x)
end
def tw31(x)
  return tw32(x) if x.size > 99
  return tw32(x)
end
def tw32(x)
  return tw33(x) if x.size > 99
  return tw33(x)
end
def tw33(x)
  return tw34(x) if x.size > 99
  return tw34(x)
end
def tw34(x)
  return tw35(x) if x.size > 99
  return tw35(x)
end
def tw35(x)
  return tw36(x) if x.size > 99
  return tw36(x)
end
def tw36(x)
  return tw37(x) if x.size > 99
  return tw37(x)
end
def tw37(x)
  return tw38(x) if x.size > 99
  return tw38(x)
end
def tw38(x)
  return tw39(x) if x.size > 99
  return tw39(x)
end
def tw39(x)
  return tw40(x) if x.size > 99
  return tw40(x)
end
def tw40(x)
  return tw41(x) if x.size > 99
  return tw41(x)
end
def tw41(x)
  return tw42(x) if x.size > 99
  return tw42(x)
end
def tw42(x)
  return tw43(x) if x.size > 99
  return tw43(x)
end
def tw43(x)
  return tw44(x) if x.size > 99
  return tw44(x)
end
def tw44(x)
  return tw45(x) if x.size > 99
  return tw45(x)
end
def tw45(a) = a << 2.5

y = []
q = rt1(y)
p q, y, q.equal?(y)

w = []
p tw1(w), w

q << "t"
p y.size
