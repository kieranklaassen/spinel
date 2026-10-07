# A `&.` call to between? on an Integer or a Float, or to clamp on a Float,
# with a boxed bound. The typed emitter has no arm for them (the first did
# not build, the second raised NoMethodError), so the call moves onto its
# builtins/ definition, under a nil test.
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

p i&.between?(id(1), id(20)), z&.between?(id(1), id(20))
p i&.between?(1, id(5)), i&.between?(id(13), 20), i&.between?(id(1.5), id(12.5))
p f&.between?(id(1.0), id(2.0)), g&.between?(id(1.0), id(2.0)), f&.between?(id(1), 2)
p f&.clamp(id(1.0), id(1.2)), g&.clamp(id(1.0), id(1.2))
p f&.clamp(1.0, id(1.2)), f&.clamp(id(2), 3.0), f&.clamp(id(nil), id(1.0))

# a nil receiver runs no argument; any other runs each once
p z&.between?(id(lg(1)), id(lg(5))), $log
p i&.between?(id(lg(1)), id(lg(5))), $log
p g&.clamp(id(lg(1.0)), id(lg(5.0))), $log

# the receiver runs once
s = Src.new(12); t = Src.new(nil)
p s.nxt&.between?(id(1), id(20)), s.n, t.nxt&.between?(id(1), id(20)), t.n

# as a receiver, in a block, with a parameter another call boxes
p f&.clamp(id(1.0), id(1.2))&.round(1), g&.clamp(id(1.0), id(1.2)).to_s
[1, 2].each { |k| p i&.between?(id(k), id(5)), z&.between?(id(k), id(5)) }
def h(v, a) = v&.between?(a, 20)
p h(i, 8), h(i, id(18)), h(z, id(18))

# a bound that does not compare raises, as it does behind a `.`
begin
  p i&.between?(id(1), id("a"))
rescue ArgumentError => e
  puts e.message
end
