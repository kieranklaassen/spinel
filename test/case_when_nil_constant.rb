# A constant holding nil is a `when nil` arm. Beside an Integer or a Float
# it was compared as a number, nil read as 0, and matched 0 and 0.0; beside
# a String, an Array or a Hash it never matched one that was nil.
NOTHING = nil
module Cfg
  NONE = nil
end

# beside a number
p(case 0 when NOTHING then :hit else :miss end)
p(case 0.0 when NOTHING then :hit else :miss end)
p(case 5 when NOTHING then :hit else :miss end)
p(case 0 when Cfg::NONE then :hit else :miss end)

# beside a String parameter called with nil, a String arm before it
def kind(r)
  case r
  when "ABCD" then "abcd"
  when NOTHING then "nothing"
  else "str"
  end
end
puts kind("ABCD"), kind("x"), kind(nil)

def blank?(s)
  case s
  when NOTHING, "" then true
  else false
  end
end
p blank?(nil), blank?(""), blank?("a")

# an element that is nil, of each kind
def int_arm(v)
  case v
  when NOTHING then "none"
  when 0 then "zero"
  else "num"
  end
end

ints = [0, 4]; strs = ["a", "q"]; flts = [0.0]; rows = [[1, 2], []]
puts int_arm(ints[0]), int_arm(ints[1]), int_arm(ints[9])
puts kind(strs[0]), kind(strs[9])
p(case flts[0] when NOTHING then :hit else :miss end)
p(case flts[9] when NOTHING then :hit else :miss end)
p(case strs[9] when "q", NOTHING then :hit else :miss end)
p(case strs[0] when "q", NOTHING then :hit else :miss end)
p(case "" when NOTHING then :hit else :miss end)
p(case rows[9] when NOTHING then :hit else :miss end)
p(case rows[1] when NOTHING then :hit else :miss end)

# an instance variable never written
class Slots
  def initialize(set)
    if set
      @i = 0; @x = 0.0; @s = ""; @map = { a: 1 }
    end
  end
  def i = @i
  def x = @x
  def s = @s
  def map = @map
end

unset = Slots.new(false); set = Slots.new(true)
p(case unset.i when NOTHING then :hit else :miss end)
p(case set.i when NOTHING then :hit else :miss end)
p(case unset.x when NOTHING then :hit else :miss end)
p(case set.x when NOTHING then :hit else :miss end)
p(case unset.s when NOTHING then :hit else :miss end)
p(case set.s when NOTHING then :hit else :miss end)
p(case unset.map when Cfg::NONE then :hit else :miss end)
p(case set.map when Cfg::NONE then :hit else :miss end)
