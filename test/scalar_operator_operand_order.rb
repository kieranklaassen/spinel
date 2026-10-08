# A builtin operator over scalars (`x + i`, `n < 3`) computes a value and
# touches nothing, so a call's operands are not put in order around it.
# Two of them are no such thing: `3 == obj` asks the object's own `==`,
# and a division raises on a zero divisor. Beside an operand that prints,
# C's unspecified order showed: the `==` ran first, or the raise came
# before the line.
class Seen
  def ==(o)
    puts "eq"
    o == 3
  end
end
def lg(n)
  puts "lg#{n}"
  n
end
def pair(a, b) = [a, b]
def kw(a:, b:) = [a, b]
def both(v) = yield(lg(6), 3 == v)
Pt = Struct.new(:x, :y)
def tried
  yield
rescue ZeroDivisionError => e
  puts e.message
end
K = 4
v = Seen.new
z = ARGV.size
zf = z.to_f

# an object's `==`, on either side of the printing operand
p pair(lg(1), 3 == v)
p pair(3 != v, lg(2))
p kw(a: lg(3), b: 3.0 == v)
p Pt.new(lg(4), 3 == v).to_a
p lg(5), 3 == v
p both(v) { |a, b| [a, b] }
t = 0
t += pair(lg(7), 3 == v).size
p t
p pair(lg(8), pair(1, 3 == v))
p pair(lg(9), (3 == v) ? 1 : 2)

# a zero divisor: the line before the raise, or no line after it
tried { p pair(lg(10), 10 / z) }
tried { p pair(10 / z, lg(11)) }
tried { p pair(lg(12), 10 % z) }
tried { p pair(lg(13), 10.5 % z) }
tried { p pair(lg(14), 10 % zf) }
tried { p pair(lg(15), 1 + 10 % z) }
tried { p kw(a: lg(16), b: 10 / (z + z)) }

# as it was: a divisor that cannot be zero, a Float division, scalars compared
p pair(lg(20), 10 / K), pair(lg(21), 10 % (K * 2)), pair(lg(22), 10.0 / z)
p pair(lg(23), 3 == z), pair(lg(24), z == nil), pair(lg(25), 10 / (z + 1))
