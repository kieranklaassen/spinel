# A method's return type is lifted from its body once more after the
# inference has settled, for a body that ends in a call to a method typed
# late. A lift crosses one call where the caller is defined before its
# callee, and the loop ran 8 times. Of 40 methods handing an empty Array
# down to the one that appends to it, the first stayed without a type and
# was emitted void: `r = fl1(x)` was nil, with nothing said. The loop now
# runs until nothing lifts.

# 45 methods, each answering the next one's value; the last appends
def fl1(x) = fl2(x)
def fl2(x) = fl3(x)
def fl3(x) = fl4(x)
def fl4(x) = fl5(x)
def fl5(x) = fl6(x)
def fl6(x) = fl7(x)
def fl7(x) = fl8(x)
def fl8(x) = fl9(x)
def fl9(x) = fl10(x)
def fl10(x) = fl11(x)
def fl11(x) = fl12(x)
def fl12(x) = fl13(x)
def fl13(x) = fl14(x)
def fl14(x) = fl15(x)
def fl15(x) = fl16(x)
def fl16(x) = fl17(x)
def fl17(x) = fl18(x)
def fl18(x) = fl19(x)
def fl19(x) = fl20(x)
def fl20(x) = fl21(x)
def fl21(x) = fl22(x)
def fl22(x) = fl23(x)
def fl23(x) = fl24(x)
def fl24(x) = fl25(x)
def fl25(x) = fl26(x)
def fl26(x) = fl27(x)
def fl27(x) = fl28(x)
def fl28(x) = fl29(x)
def fl29(x) = fl30(x)
def fl30(x) = fl31(x)
def fl31(x) = fl32(x)
def fl32(x) = fl33(x)
def fl33(x) = fl34(x)
def fl34(x) = fl35(x)
def fl35(x) = fl36(x)
def fl36(x) = fl37(x)
def fl37(x) = fl38(x)
def fl38(x) = fl39(x)
def fl39(x) = fl40(x)
def fl40(x) = fl41(x)
def fl41(x) = fl42(x)
def fl42(x) = fl43(x)
def fl43(x) = fl44(x)
def fl44(x) = fl45(x)
def fl45(a) = a << 2.5

# each answering the call from both arms of an if
def cd1(x)
  if x.size > 99
    cd2(x)
  else
    cd2(x)
  end
end
def cd2(x)
  if x.size > 99
    cd3(x)
  else
    cd3(x)
  end
end
def cd3(x)
  if x.size > 99
    cd4(x)
  else
    cd4(x)
  end
end
def cd4(x)
  if x.size > 99
    cd5(x)
  else
    cd5(x)
  end
end
def cd5(x)
  if x.size > 99
    cd6(x)
  else
    cd6(x)
  end
end
def cd6(x)
  if x.size > 99
    cd7(x)
  else
    cd7(x)
  end
end
def cd7(x)
  if x.size > 99
    cd8(x)
  else
    cd8(x)
  end
end
def cd8(x)
  if x.size > 99
    cd9(x)
  else
    cd9(x)
  end
end
def cd9(x)
  if x.size > 99
    cd10(x)
  else
    cd10(x)
  end
end
def cd10(x)
  if x.size > 99
    cd11(x)
  else
    cd11(x)
  end
end
def cd11(x)
  if x.size > 99
    cd12(x)
  else
    cd12(x)
  end
end
def cd12(x)
  if x.size > 99
    cd13(x)
  else
    cd13(x)
  end
end
def cd13(x)
  if x.size > 99
    cd14(x)
  else
    cd14(x)
  end
end
def cd14(x)
  if x.size > 99
    cd15(x)
  else
    cd15(x)
  end
end
def cd15(x)
  if x.size > 99
    cd16(x)
  else
    cd16(x)
  end
end
def cd16(x)
  if x.size > 99
    cd17(x)
  else
    cd17(x)
  end
end
def cd17(x)
  if x.size > 99
    cd18(x)
  else
    cd18(x)
  end
end
def cd18(x)
  if x.size > 99
    cd19(x)
  else
    cd19(x)
  end
end
def cd19(x)
  if x.size > 99
    cd20(x)
  else
    cd20(x)
  end
end
def cd20(x)
  if x.size > 99
    cd21(x)
  else
    cd21(x)
  end
end
def cd21(x)
  if x.size > 99
    cd22(x)
  else
    cd22(x)
  end
end
def cd22(x)
  if x.size > 99
    cd23(x)
  else
    cd23(x)
  end
end
def cd23(x)
  if x.size > 99
    cd24(x)
  else
    cd24(x)
  end
end
def cd24(x)
  if x.size > 99
    cd25(x)
  else
    cd25(x)
  end
end
def cd25(x)
  if x.size > 99
    cd26(x)
  else
    cd26(x)
  end
end
def cd26(x)
  if x.size > 99
    cd27(x)
  else
    cd27(x)
  end
end
def cd27(x)
  if x.size > 99
    cd28(x)
  else
    cd28(x)
  end
end
def cd28(x)
  if x.size > 99
    cd29(x)
  else
    cd29(x)
  end
end
def cd29(x)
  if x.size > 99
    cd30(x)
  else
    cd30(x)
  end
end
def cd30(x)
  if x.size > 99
    cd31(x)
  else
    cd31(x)
  end
end
def cd31(x)
  if x.size > 99
    cd32(x)
  else
    cd32(x)
  end
end
def cd32(x)
  if x.size > 99
    cd33(x)
  else
    cd33(x)
  end
end
def cd33(x)
  if x.size > 99
    cd34(x)
  else
    cd34(x)
  end
end
def cd34(x)
  if x.size > 99
    cd35(x)
  else
    cd35(x)
  end
end
def cd35(x)
  if x.size > 99
    cd36(x)
  else
    cd36(x)
  end
end
def cd36(x)
  if x.size > 99
    cd37(x)
  else
    cd37(x)
  end
end
def cd37(x)
  if x.size > 99
    cd38(x)
  else
    cd38(x)
  end
end
def cd38(x)
  if x.size > 99
    cd39(x)
  else
    cd39(x)
  end
end
def cd39(x)
  if x.size > 99
    cd40(x)
  else
    cd40(x)
  end
end
def cd40(x)
  if x.size > 99
    cd41(x)
  else
    cd41(x)
  end
end
def cd41(x)
  if x.size > 99
    cd42(x)
  else
    cd42(x)
  end
end
def cd42(x)
  if x.size > 99
    cd43(x)
  else
    cd43(x)
  end
end
def cd43(x)
  if x.size > 99
    cd44(x)
  else
    cd44(x)
  end
end
def cd44(x)
  if x.size > 99
    cd45(x)
  else
    cd45(x)
  end
end
def cd45(a) = a << 7

# instance methods
class Far
  def hs1(x) = hs2(x)
  def hs2(x) = hs3(x)
  def hs3(x) = hs4(x)
  def hs4(x) = hs5(x)
  def hs5(x) = hs6(x)
  def hs6(x) = hs7(x)
  def hs7(x) = hs8(x)
  def hs8(x) = hs9(x)
  def hs9(x) = hs10(x)
  def hs10(x) = hs11(x)
  def hs11(x) = hs12(x)
  def hs12(x) = hs13(x)
  def hs13(x) = hs14(x)
  def hs14(x) = hs15(x)
  def hs15(x) = hs16(x)
  def hs16(x) = hs17(x)
  def hs17(x) = hs18(x)
  def hs18(x) = hs19(x)
  def hs19(x) = hs20(x)
  def hs20(x) = hs21(x)
  def hs21(x) = hs22(x)
  def hs22(x) = hs23(x)
  def hs23(x) = hs24(x)
  def hs24(x) = hs25(x)
  def hs25(x) = hs26(x)
  def hs26(x) = hs27(x)
  def hs27(x) = hs28(x)
  def hs28(x) = hs29(x)
  def hs29(x) = hs30(x)
  def hs30(x) = hs31(x)
  def hs31(x) = hs32(x)
  def hs32(x) = hs33(x)
  def hs33(x) = hs34(x)
  def hs34(x) = hs35(x)
  def hs35(x) = hs36(x)
  def hs36(x) = hs37(x)
  def hs37(x) = hs38(x)
  def hs38(x) = hs39(x)
  def hs39(x) = hs40(x)
  def hs40(x) = hs41(x)
  def hs41(x) = hs42(x)
  def hs42(x) = hs43(x)
  def hs43(x) = hs44(x)
  def hs44(x) = hs45(x)
  def hs45(a) = a << "s"
end

x = []
r = fl1(x)
p r, x, r.equal?(x)

z = []
p cd1(z), z

h = []
g = Far.new.hs1(h)
p g, g.equal?(h)

# the value is the Array handed in: an append through it shows in x
r << 3.5
p x.size, g.size
