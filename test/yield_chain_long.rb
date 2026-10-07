# A block handed down through 40 methods, each one's block yielding to its
# own caller's: the value the block answers comes back up through all of
# them. The analysis answered a `yield`'s type through the call sites on a
# stack of 32 methods, and from 34 methods the call's value was nil.

# each method's block yields to the block of the method it is written in
def relay1(x)
  relay2(x) { |v| yield v }
end
def relay2(x)
  relay3(x) { |v| yield v }
end
def relay3(x)
  relay4(x) { |v| yield v }
end
def relay4(x)
  relay5(x) { |v| yield v }
end
def relay5(x)
  relay6(x) { |v| yield v }
end
def relay6(x)
  relay7(x) { |v| yield v }
end
def relay7(x)
  relay8(x) { |v| yield v }
end
def relay8(x)
  relay9(x) { |v| yield v }
end
def relay9(x)
  relay10(x) { |v| yield v }
end
def relay10(x)
  relay11(x) { |v| yield v }
end
def relay11(x)
  relay12(x) { |v| yield v }
end
def relay12(x)
  relay13(x) { |v| yield v }
end
def relay13(x)
  relay14(x) { |v| yield v }
end
def relay14(x)
  relay15(x) { |v| yield v }
end
def relay15(x)
  relay16(x) { |v| yield v }
end
def relay16(x)
  relay17(x) { |v| yield v }
end
def relay17(x)
  relay18(x) { |v| yield v }
end
def relay18(x)
  relay19(x) { |v| yield v }
end
def relay19(x)
  relay20(x) { |v| yield v }
end
def relay20(x)
  relay21(x) { |v| yield v }
end
def relay21(x)
  relay22(x) { |v| yield v }
end
def relay22(x)
  relay23(x) { |v| yield v }
end
def relay23(x)
  relay24(x) { |v| yield v }
end
def relay24(x)
  relay25(x) { |v| yield v }
end
def relay25(x)
  relay26(x) { |v| yield v }
end
def relay26(x)
  relay27(x) { |v| yield v }
end
def relay27(x)
  relay28(x) { |v| yield v }
end
def relay28(x)
  relay29(x) { |v| yield v }
end
def relay29(x)
  relay30(x) { |v| yield v }
end
def relay30(x)
  relay31(x) { |v| yield v }
end
def relay31(x)
  relay32(x) { |v| yield v }
end
def relay32(x)
  relay33(x) { |v| yield v }
end
def relay33(x)
  relay34(x) { |v| yield v }
end
def relay34(x)
  relay35(x) { |v| yield v }
end
def relay35(x)
  relay36(x) { |v| yield v }
end
def relay36(x)
  relay37(x) { |v| yield v }
end
def relay37(x)
  relay38(x) { |v| yield v }
end
def relay38(x)
  relay39(x) { |v| yield v }
end
def relay39(x)
  relay40(x) { |v| yield v }
end
def relay40(x) = yield(x + 1)
p relay1(1) { |v| v * 2 }

# the block handed on as `&b`, and answering a String
def pass1(x, &b) = pass2(x, &b)
def pass2(x, &b) = pass3(x, &b)
def pass3(x, &b) = pass4(x, &b)
def pass4(x, &b) = pass5(x, &b)
def pass5(x, &b) = pass6(x, &b)
def pass6(x, &b) = pass7(x, &b)
def pass7(x, &b) = pass8(x, &b)
def pass8(x, &b) = pass9(x, &b)
def pass9(x, &b) = pass10(x, &b)
def pass10(x, &b) = pass11(x, &b)
def pass11(x, &b) = pass12(x, &b)
def pass12(x, &b) = pass13(x, &b)
def pass13(x, &b) = pass14(x, &b)
def pass14(x, &b) = pass15(x, &b)
def pass15(x, &b) = pass16(x, &b)
def pass16(x, &b) = pass17(x, &b)
def pass17(x, &b) = pass18(x, &b)
def pass18(x, &b) = pass19(x, &b)
def pass19(x, &b) = pass20(x, &b)
def pass20(x, &b) = pass21(x, &b)
def pass21(x, &b) = pass22(x, &b)
def pass22(x, &b) = pass23(x, &b)
def pass23(x, &b) = pass24(x, &b)
def pass24(x, &b) = pass25(x, &b)
def pass25(x, &b) = pass26(x, &b)
def pass26(x, &b) = pass27(x, &b)
def pass27(x, &b) = pass28(x, &b)
def pass28(x, &b) = pass29(x, &b)
def pass29(x, &b) = pass30(x, &b)
def pass30(x, &b) = pass31(x, &b)
def pass31(x, &b) = pass32(x, &b)
def pass32(x, &b) = pass33(x, &b)
def pass33(x, &b) = pass34(x, &b)
def pass34(x, &b) = pass35(x, &b)
def pass35(x, &b) = pass36(x, &b)
def pass36(x, &b) = pass37(x, &b)
def pass37(x, &b) = pass38(x, &b)
def pass38(x, &b) = pass39(x, &b)
def pass39(x, &b) = pass40(x, &b)
def pass40(x) = yield(x + "b")
p pass1("a") { |v| v + "c" }

# instance methods, the last one asking whether it has a block
class Relay
  def step1(x)
    step2(x) { |v| yield v }
  end
  def step2(x)
    step3(x) { |v| yield v }
  end
  def step3(x)
    step4(x) { |v| yield v }
  end
  def step4(x)
    step5(x) { |v| yield v }
  end
  def step5(x)
    step6(x) { |v| yield v }
  end
  def step6(x)
    step7(x) { |v| yield v }
  end
  def step7(x)
    step8(x) { |v| yield v }
  end
  def step8(x)
    step9(x) { |v| yield v }
  end
  def step9(x)
    step10(x) { |v| yield v }
  end
  def step10(x)
    step11(x) { |v| yield v }
  end
  def step11(x)
    step12(x) { |v| yield v }
  end
  def step12(x)
    step13(x) { |v| yield v }
  end
  def step13(x)
    step14(x) { |v| yield v }
  end
  def step14(x)
    step15(x) { |v| yield v }
  end
  def step15(x)
    step16(x) { |v| yield v }
  end
  def step16(x)
    step17(x) { |v| yield v }
  end
  def step17(x)
    step18(x) { |v| yield v }
  end
  def step18(x)
    step19(x) { |v| yield v }
  end
  def step19(x)
    step20(x) { |v| yield v }
  end
  def step20(x)
    step21(x) { |v| yield v }
  end
  def step21(x)
    step22(x) { |v| yield v }
  end
  def step22(x)
    step23(x) { |v| yield v }
  end
  def step23(x)
    step24(x) { |v| yield v }
  end
  def step24(x)
    step25(x) { |v| yield v }
  end
  def step25(x)
    step26(x) { |v| yield v }
  end
  def step26(x)
    step27(x) { |v| yield v }
  end
  def step27(x)
    step28(x) { |v| yield v }
  end
  def step28(x)
    step29(x) { |v| yield v }
  end
  def step29(x)
    step30(x) { |v| yield v }
  end
  def step30(x)
    step31(x) { |v| yield v }
  end
  def step31(x)
    step32(x) { |v| yield v }
  end
  def step32(x)
    step33(x) { |v| yield v }
  end
  def step33(x)
    step34(x) { |v| yield v }
  end
  def step34(x)
    step35(x) { |v| yield v }
  end
  def step35(x)
    step36(x) { |v| yield v }
  end
  def step36(x)
    step37(x) { |v| yield v }
  end
  def step37(x)
    step38(x) { |v| yield v }
  end
  def step38(x)
    step39(x) { |v| yield v }
  end
  def step39(x)
    step40(x) { |v| yield v }
  end
  def step40(x) = block_given? ? yield(x + 1) : 0
end
p Relay.new.step1(1) { |v| v * 3 }

# two call sites whose blocks answer different types, and a block that may answer nil
def site1(x)
  site2(x) { |v| yield v }
end
def site2(x)
  site3(x) { |v| yield v }
end
def site3(x)
  site4(x) { |v| yield v }
end
def site4(x)
  site5(x) { |v| yield v }
end
def site5(x)
  site6(x) { |v| yield v }
end
def site6(x)
  site7(x) { |v| yield v }
end
def site7(x)
  site8(x) { |v| yield v }
end
def site8(x)
  site9(x) { |v| yield v }
end
def site9(x)
  site10(x) { |v| yield v }
end
def site10(x)
  site11(x) { |v| yield v }
end
def site11(x)
  site12(x) { |v| yield v }
end
def site12(x)
  site13(x) { |v| yield v }
end
def site13(x)
  site14(x) { |v| yield v }
end
def site14(x)
  site15(x) { |v| yield v }
end
def site15(x)
  site16(x) { |v| yield v }
end
def site16(x)
  site17(x) { |v| yield v }
end
def site17(x)
  site18(x) { |v| yield v }
end
def site18(x)
  site19(x) { |v| yield v }
end
def site19(x)
  site20(x) { |v| yield v }
end
def site20(x)
  site21(x) { |v| yield v }
end
def site21(x)
  site22(x) { |v| yield v }
end
def site22(x)
  site23(x) { |v| yield v }
end
def site23(x)
  site24(x) { |v| yield v }
end
def site24(x)
  site25(x) { |v| yield v }
end
def site25(x)
  site26(x) { |v| yield v }
end
def site26(x)
  site27(x) { |v| yield v }
end
def site27(x)
  site28(x) { |v| yield v }
end
def site28(x)
  site29(x) { |v| yield v }
end
def site29(x)
  site30(x) { |v| yield v }
end
def site30(x)
  site31(x) { |v| yield v }
end
def site31(x)
  site32(x) { |v| yield v }
end
def site32(x)
  site33(x) { |v| yield v }
end
def site33(x)
  site34(x) { |v| yield v }
end
def site34(x)
  site35(x) { |v| yield v }
end
def site35(x)
  site36(x) { |v| yield v }
end
def site36(x)
  site37(x) { |v| yield v }
end
def site37(x)
  site38(x) { |v| yield v }
end
def site38(x)
  site39(x) { |v| yield v }
end
def site39(x)
  site40(x) { |v| yield v }
end
def site40(x) = yield(x)
p site1(1) { |v| v * 2 }
p site1(2) { |v| v.to_s }
p site1(3) { |v| v > 5 ? v : nil }
p site1(9) { |v| v > 5 ? v : nil }

# the block handed on as a proc each method calls, through 65 methods: these
# have functions of their own, so the chain is as long as it likes
def call1(x, &b) = call2(x) { |v| b.call(v) }
def call2(x, &b) = call3(x) { |v| b.call(v) }
def call3(x, &b) = call4(x) { |v| b.call(v) }
def call4(x, &b) = call5(x) { |v| b.call(v) }
def call5(x, &b) = call6(x) { |v| b.call(v) }
def call6(x, &b) = call7(x) { |v| b.call(v) }
def call7(x, &b) = call8(x) { |v| b.call(v) }
def call8(x, &b) = call9(x) { |v| b.call(v) }
def call9(x, &b) = call10(x) { |v| b.call(v) }
def call10(x, &b) = call11(x) { |v| b.call(v) }
def call11(x, &b) = call12(x) { |v| b.call(v) }
def call12(x, &b) = call13(x) { |v| b.call(v) }
def call13(x, &b) = call14(x) { |v| b.call(v) }
def call14(x, &b) = call15(x) { |v| b.call(v) }
def call15(x, &b) = call16(x) { |v| b.call(v) }
def call16(x, &b) = call17(x) { |v| b.call(v) }
def call17(x, &b) = call18(x) { |v| b.call(v) }
def call18(x, &b) = call19(x) { |v| b.call(v) }
def call19(x, &b) = call20(x) { |v| b.call(v) }
def call20(x, &b) = call21(x) { |v| b.call(v) }
def call21(x, &b) = call22(x) { |v| b.call(v) }
def call22(x, &b) = call23(x) { |v| b.call(v) }
def call23(x, &b) = call24(x) { |v| b.call(v) }
def call24(x, &b) = call25(x) { |v| b.call(v) }
def call25(x, &b) = call26(x) { |v| b.call(v) }
def call26(x, &b) = call27(x) { |v| b.call(v) }
def call27(x, &b) = call28(x) { |v| b.call(v) }
def call28(x, &b) = call29(x) { |v| b.call(v) }
def call29(x, &b) = call30(x) { |v| b.call(v) }
def call30(x, &b) = call31(x) { |v| b.call(v) }
def call31(x, &b) = call32(x) { |v| b.call(v) }
def call32(x, &b) = call33(x) { |v| b.call(v) }
def call33(x, &b) = call34(x) { |v| b.call(v) }
def call34(x, &b) = call35(x) { |v| b.call(v) }
def call35(x, &b) = call36(x) { |v| b.call(v) }
def call36(x, &b) = call37(x) { |v| b.call(v) }
def call37(x, &b) = call38(x) { |v| b.call(v) }
def call38(x, &b) = call39(x) { |v| b.call(v) }
def call39(x, &b) = call40(x) { |v| b.call(v) }
def call40(x, &b) = call41(x) { |v| b.call(v) }
def call41(x, &b) = call42(x) { |v| b.call(v) }
def call42(x, &b) = call43(x) { |v| b.call(v) }
def call43(x, &b) = call44(x) { |v| b.call(v) }
def call44(x, &b) = call45(x) { |v| b.call(v) }
def call45(x, &b) = call46(x) { |v| b.call(v) }
def call46(x, &b) = call47(x) { |v| b.call(v) }
def call47(x, &b) = call48(x) { |v| b.call(v) }
def call48(x, &b) = call49(x) { |v| b.call(v) }
def call49(x, &b) = call50(x) { |v| b.call(v) }
def call50(x, &b) = call51(x) { |v| b.call(v) }
def call51(x, &b) = call52(x) { |v| b.call(v) }
def call52(x, &b) = call53(x) { |v| b.call(v) }
def call53(x, &b) = call54(x) { |v| b.call(v) }
def call54(x, &b) = call55(x) { |v| b.call(v) }
def call55(x, &b) = call56(x) { |v| b.call(v) }
def call56(x, &b) = call57(x) { |v| b.call(v) }
def call57(x, &b) = call58(x) { |v| b.call(v) }
def call58(x, &b) = call59(x) { |v| b.call(v) }
def call59(x, &b) = call60(x) { |v| b.call(v) }
def call60(x, &b) = call61(x) { |v| b.call(v) }
def call61(x, &b) = call62(x) { |v| b.call(v) }
def call62(x, &b) = call63(x) { |v| b.call(v) }
def call63(x, &b) = call64(x) { |v| b.call(v) }
def call64(x, &b) = call65(x) { |v| b.call(v) }
def call65(x) = yield(x)
p call1(:a) { |v| v }
