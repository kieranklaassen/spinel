# eql?, equal? and Float#=== evaluate their receiver when the argument can
# never be equal. The receiver was left out, and what it does with it; with
# an argument of more than one kind it came after the argument.
$n = 0
$log = +""

class K; end

class Pt
  attr_reader :x
  def initialize(x); @x = x; end
end

def int; $n += 1; 1; end
def flt; $n += 1; 1.5; end
def obj; $n += 1; K.new; end
def pt; $n += 1; Pt.new(1); end
def r; $log << "r"; 1; end
def f; $log << "f"; 1.5; end
def a(v); $log << "a"; v; end

p int.equal?(nil), int.eql?("s"), int.eql?(1.0), int.equal?(:a), int.eql?([1])
puts $n
p flt.equal?(nil), flt.eql?(1), flt.eql?("s"), flt.equal?(true)
puts $n
p flt === [1], flt === "s"
puts $n
p obj.eql?(nil), obj.eql?(1), obj.eql?("s")
puts $n
p pt.eql?(nil), pt.eql?(1)
puts $n

# the receiver, then the argument
p r.eql?(a(nil)), f.eql?(a(nil)), f === a("s")
puts $log
$log.clear
mixed = ARGV.empty? ? "s" : 1
p r.eql?(a(mixed)), f.equal?(a(mixed))
puts $log
one_or_s = ARGV.empty? ? 1 : "s"
p int.eql?(one_or_s), int.eql?(mixed), flt.equal?(mixed), flt.eql?(one_or_s)
puts $n

# as before where the argument can be equal, or the receiver is a variable
p int.eql?(1), flt.equal?(1.5), flt === 1.5
x = 1
y = 1.5
p x.eql?(nil), y.equal?("s"), y === [1]
puts $n
