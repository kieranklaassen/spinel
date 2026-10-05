# `&.` on a nil Integer or Float answers nil for the builtins written in
# Ruby (builtins/integer.rb, builtins/comparable.rb) too, and runs none of
# their arguments. The call was rewritten into the builtin's per-call copy
# with the receiver as its first argument, which dropped the operator: the
# copy took the nil as its self and raised NoMethodError.
$log = []
def lg(x) = ($log << x; x)
def int(v) = v ? 12 : nil
def flt(v) = v ? 1.5 : nil
def big(v) = v ? 2**70 : nil

# every such builtin, a nil receiver then a number
[false, true].each do |live|
  $log = []
  i = int(live)
  f = flt(live)
  p i&.digits, i&.digits(lg(2)), i&.bit_length
  p i&.gcd(lg(8)), i&.lcm(lg(8)), i&.gcdlcm(lg(8))
  p i&.ceildiv(lg(5)), i&.remainder(lg(5)), i&.fdiv(lg(5))
  p i&.between?(lg(1), lg(20)), i&.clamp(lg(1), lg(2))
  p f&.between?(lg(1.0), lg(2.0)), f&.clamp(lg(1.0), lg(1.2))
  p $log
end

# as a statement, with a local the arguments write
$log = []
n = 0
i = int(false)
i&.digits
i&.clamp(n += 1, n += 1)
p n
i = int(true)
i&.digits
i&.clamp(n += 1, n += 1)
p n

# the receiver runs once, and a chain stops at the nil
def int2(x) = (lg(x); x > 0 ? 12 : nil)
p int2(0)&.clamp(lg(1), lg(2)), int2(1)&.clamp(lg(1), lg(2)), $log
$log = []
p int2(0)&.gcd(lg(8))&.digits, int2(1)&.gcd(lg(8))&.digits, $log

# an instance variable, an interpolation, a test, a default
class C
  def initialize(n) = @n = n
  def a = @n&.clamp(lg(1), lg(2))
  def b = @n&.digits
  def c = "<#{@n&.gcd(8)}>"
  def d = @n&.between?(1, 20) ? "in" : "out"
  def e(x = @n&.lcm(5)) = x
end
$log = []
[C.new(int(false)), C.new(int(true))].each { |o| p o.a, o.b, o.c, o.d, o.e }
p $log

# in a loop, a block, a lambda and a method; `||` on the answer
i = 0
while i < 4
  n = int(i.odd?)
  p n&.ceildiv(i + 1), n&.fdiv(2) || -1.0
  i += 1
end
$log = []
p [int(false), int(true)].map { |x| x&.clamp(lg(1), lg(20)) }, $log
pr = ->(x) { x&.remainder(lg(5)) }
p pr.call(int(false)), pr.call(int(true)), $log
def m(x) = x&.gcd(8) || 0
p m(int(false)), m(int(true))

# a Bignum receiver and Bignum arguments
b = big(false)
p b&.digits(2**40), b&.gcd(2**69), b&.clamp(1, 2**71), b&.bit_length
b = big(true)
p b&.digits(2**40), b&.gcd(2**69), b&.clamp(1, 2**71), b&.bit_length
i = int(true)
p i&.ceildiv(2**70), i&.remainder(2**70)

# an argument beside the call, a Range to clamp, a raise under the call
def f(a, b) = [a, b]
$log = []
[false, true].each do |live|
  i = int(live)
  p f(i&.clamp(lg(1), lg(2)), lg(9)), [i&.digits, lg(8)]
  p i&.clamp(1..5), i&.clamp(..5)
  v = begin
    i&.clamp(5, 1)
  rescue ArgumentError
    :raised
  end
  p v
end
p $log

# a member, an element and a miss
s = Struct.new(:n)
p s.new(int(false)).n&.clamp(1, 2), s.new(int(true)).n&.clamp(1, 2)
a = [12]
p a[0]&.digits, a[5]&.digits, a.first&.lcm(5), [].first&.lcm(5)
