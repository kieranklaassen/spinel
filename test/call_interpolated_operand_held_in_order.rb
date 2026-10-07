# An interpolated String among a call's operands is made where it stands and
# held by nothing. One that runs a call of its own was left beside the other
# operands as arguments of one C call, in C's order; one written ahead of a
# call that can change what it reads was too.

def one = 1
def ms(n) = "s#{n}t"
def rr(n) = ["x_#{Process.pid}", n]

# beside a call's result: whichever C made first was freed by the other
# (an abort under SPINEL_GC_STRESS=2)
s = rr(1)
puts s.inspect.gsub("_#{Process.pid}", "")
puts rr(2).inspect.gsub("_#{Process.pid}", "")
puts ms(1).gsub("s#{one}", "q")
puts ms(1).upcase.sub("S#{one}", "q#{one}")

# ...and in a plain run, built with gcc: the String was made first, and
# the receiver's allocations freed it (20 for 0)
def label(n)
  s = ""
  30000.times { |i| s = "q#{i % 1000}" }
  "s#{n % 1000}t"
end
def k(n) = n % 1000
wrong = 0
20.times { |n| wrong += 1 unless label(n).include?("s#{k(n)}") }
p wrong

# ...and beside a String made in place it is the operand that runs: left
# in the C call, the one made first was freed by the other's call (20 for
# 0, the first line built with gcc and the second with clang)
def kk(n)
  s = ""
  30000.times { |i| s = "q#{i % 1000}" }
  n % 10
end
wrong = 0
10.times do |n|
  wrong += 1 unless "a#{kk(n)}b".include?("#{n % 10}")
  wrong += 1 unless "a#{n % 10}".center(9, "*#{kk(n)}").include?("a#{n % 10}")
end
p wrong

# Ruby's order: gcc ran the argument's call first
$log = []
def a(n) = ($log << "a#{n}"; "s#{n}t")
def b(n) = ($log << "b#{n}"; n)
p a(1).include?("s#{b(1)}")
p a(3).sub("s#{b(3)}", "q#{b(5)}")
p "x#{b(6)}".include?("#{b(7)}")
p $log.join(",")

# written ahead of a call, reading a String: made first and held while the
# call runs (false for true under SPINEL_GC_STRESS=2)
def root(n)
  s = ""
  3000.times { |i| s = "q#{i % 100}" }
  "ab#{n}"
end
dir = "ab1x"
p "#{dir}/a".start_with?(root(1))

# ...and it reads the String before the call changes it in place
def app(s) = (s << "x"; "ab")
t = +"ab"
p "#{t}-" + app(t)
p "#{t}".include?(app(t))
arr = [1, 2]
def add(arr) = (arr.push(3); "z")
p "#{arr}" + add(arr)

# ...or an ivar a later interpolated String's call assigns: clang read it
# first, gcc after ("x0 y1" and "x2")
class Ord
  def initialize = (@n = 0; @s = "x0 x1")
  def bump = @n += 1
  def a = @s.sub("x#{@n}", "y#{bump}")
  def b = "x#{bump}".sub("x#{@n}", "y#{bump}")
end
o = Ord.new
puts o.a
puts o.b

# ...or an Integer local the call assigns, through a lambda a builtin runs
# or in its own argument ("5-a" and "2-2", built with either compiler)
x = 1
l = ->(v) { x = 5; "a" }
p "#{x}-" + [1].map(&l).join
def id(s) = s
y = 1
p "#{y}-" + id((y += 1).to_s)
