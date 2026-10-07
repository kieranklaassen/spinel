# Two interpolated Strings among a call's operands are both made where they
# stand, as arguments of one C call, and held by nothing: making the second
# could free the first (an abort or a wrong answer under SPINEL_GC_STRESS=2).

def ms(n) = "s#{n}t"

n = 1
s = "s1t"

# the receiver and an argument
p "as#{n}b".include?("s#{n}")
p "x#{n}y".index("#{n}")
p "a#{n}".casecmp?("A#{n}")

# two arguments, beside a local, a call's result and a third String
puts s.sub("s#{n}", "q#{n}")
puts s.gsub("s#{n}", "q#{n}")
puts s.tr("s#{n}", "q#{n}")
puts ms(1).sub("s#{n}", "q#{n}")
puts "s#{n}t".sub("s#{n}", "q#{n}")
p "a#{n}".start_with?("b#{n}", "a#{n}")
p "a#{n}".between?("a#{n}", "b#{n}")
puts "a#{n}".center(9, "*#{n}")

# beside a reader's value or an element read, which run nothing and stay in
# the call
class Box
  attr_reader :name
  def initialize = @name = "s1t"
end
o = Box.new
names = ["s1t"]
puts o.name.sub("s#{n}", "q#{n}")
puts names[0].sub("s#{n}", "q#{n}")
puts o.name.tr("s#{n}", "q#{n}").sub("q#{n}", "r#{n}")

# an arm that makes the last one beside a call of its own: concat folds its
# first argument in, sub! on a String an Array also holds copies its receiver
puts s.dup.concat("s#{n}", "q#{n}")
x = "as#{n}tb"
kept = [x]
x.sub!("s#{n}", "q#{n}")
puts kept[0]

# in a loop, each turn's Strings its own
hits = 0
200.times { |i| hits += 1 if "a#{i}b".include?("#{i % 10}") }
p hits

# an arm that holds its operands itself keeps doing so, and one that takes
# them one at a time holds nothing across a make
p "a#{n}" + "b#{n}"
p ["a#{n}", "b#{n}"].join("-")
p s.start_with?("q#{n}", "s#{n}")
p s.between?("r#{n}", "t#{n}")
