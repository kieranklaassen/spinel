# `&.` on a nil Integer or Float answers nil for the builtins written in
# Ruby (builtins/integer.rb, builtins/comparable.rb) too. The call was
# rewritten into the builtin's per-call copy with the receiver as its first
# argument, which dropped the operator: the copy took the nil as its self
# and raised NoMethodError.
$log = []
def lg(x) = ($log << x; x)
def int(v) = v ? 12 : nil
def flt(v) = v ? 1.5 : nil
def big(v) = v ? 2**70 : nil

# every such builtin, a nil receiver then a number
[false, true].each do |live|
  i = int(live)
  f = flt(live)
  p i&.digits, i&.digits(2), i&.bit_length
  p i&.gcd(8), i&.lcm(8), i&.gcdlcm(8)
  p i&.ceildiv(5), i&.remainder(5), i&.fdiv(5)
  p i&.between?(1, 20), i&.clamp(1, 2)
  p f&.between?(1.0, 2.0), f&.clamp(1.0, 1.2)
end

# as a statement, and with variables for arguments; a nil answers before
# the bounds are compared
lo = 1
hi = 9
i = int(false)
i&.digits
i&.clamp(lo, hi)
p i&.clamp(lo, hi), i&.clamp(hi, lo)
i = int(true)
i&.digits
i&.clamp(lo, hi)
p i&.clamp(lo, hi)

# the receiver runs once, and a chain stops at the nil
def int2(x) = (lg(x); x > 0 ? 12 : nil)
p int2(0)&.clamp(1, 2), int2(1)&.clamp(1, 2), $log
$log = []
p int2(0)&.gcd(8)&.digits, int2(1)&.gcd(8)&.digits, $log

# an instance variable, an interpolation, a test, a default
class C
  def initialize(n) = @n = n
  def a = @n&.clamp(1, 2)
  def b = @n&.digits
  def c = "<#{@n&.gcd(8)}>"
  def d = @n&.between?(1, 20) ? "in" : "out"
  def e(x = @n&.lcm(5)) = x
end
[C.new(int(false)), C.new(int(true))].each { |o| p o.a, o.b, o.c, o.d, o.e }

# in a loop, a block, a lambda and a method; `||` on the answer
i = 0
while i < 4
  n = int(i.odd?)
  k = i + 1
  p n&.ceildiv(k), n&.fdiv(2) || -1.0
  i += 1
end
p [int(false), int(true)].map { |x| x&.clamp(1, 20) }
pr = ->(x) { x&.remainder(5) }
p pr.call(int(false)), pr.call(int(true))
def m(x) = x&.gcd(8) || 0
p m(int(false)), m(int(true))

# a Bignum receiver and Bignum arguments
b40 = 2**40
b69 = 2**69
b70 = 2**70
b71 = 2**71
b = big(false)
p b&.digits(b40), b&.gcd(b69), b&.clamp(1, b71), b&.bit_length
b = big(true)
p b&.digits(b40), b&.gcd(b69), b&.clamp(1, b71), b&.bit_length
i = int(true)
p i&.ceildiv(b70), i&.remainder(b70)

# an argument beside the call, a Range to clamp, a raise under the call
def f(a, b) = [a, b]
$log = []
[false, true].each do |live|
  i = int(live)
  p f(i&.clamp(1, 2), lg(9)), [i&.digits, lg(8)]
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
