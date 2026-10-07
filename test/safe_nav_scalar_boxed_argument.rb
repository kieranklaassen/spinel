# A `&.` call to a scalar method written in Ruby (builtins/) with a boxed
# argument. The typed emitter such a call was left on does not serve a boxed
# argument, so the call moves onto its builtins definition, under a nil test.
$log = []
def lg(x) = ($log << x; x)
def id(x) = x
id(:s)
def int(v) = v ? 12 : nil
def flt(v) = v ? 1.5 : nil
class Src
  attr_reader :n
  def initialize(v) = (@v = v; @n = 0)
  def nxt = (@n += 1; @v)
end
i = int(true); z = int(false); f = flt(true); g = flt(false)

p i&.remainder(id(5.0)), z&.remainder(id(5.0))            # 2 for 2.0
p f&.clamp(id(1.0), id(1.2)), g&.clamp(id(1.0), id(1.2))  # NoMethodError
p i&.between?(id(1), id(20)), z&.between?(id(1), id(20))  # did not build
p f&.between?(id(1.0), id(2.0)), g&.between?(id(1.0), id(2.0))
p i&.gcd(id(8)), i&.clamp(id(1), id(5)), i&.fdiv(id(5)), z&.gcd(id(8))

# a nil receiver runs no argument; any other runs each once
p z&.clamp(id(lg(1)), id(lg(5))), $log
p i&.clamp(id(lg(1)), id(lg(5))), $log

# the receiver runs once
s = Src.new(12); t = Src.new(nil)
p s.nxt&.remainder(id(5.0)), s.n, t.nxt&.remainder(id(5.0)), t.n

# as a receiver, in a block, with a parameter another call boxes
p i&.remainder(id(5.0))&.round, z&.remainder(id(5.0)).to_s
[1, 2].each { |k| p i&.clamp(id(k), id(5)), z&.clamp(id(k), id(5)) }
def h(v, a) = v&.gcd(a)
p h(i, 8), h(i, id(18)), h(z, id(18))
