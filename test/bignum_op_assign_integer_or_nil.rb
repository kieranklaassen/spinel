# spinel: int64
# `x += n` on a Bignum local, global or class variable, with an Integer `n`
# that is nil. The operand's slot holds the nil as the Integer -2**63, and
# the write made a Bignum of that number: `x += n` answered x - 2**63.
def sm(k, on) = on ? k : nil
def show
  r = yield
  puts r.inspect
rescue => e
  puts "#{e.class}: #{e.message}"
end
class Acc
  @@c = 2**70
  def add(n) = (@@c += n; @@c)
end
$g = 2**70
[true, false].each do |on|
  n = sm(3, on)
  x = 2**70
  show { x += n; x }
  show { x -= n; x }
  show { x *= n; x }
  show { x /= n; x }
  show { x %= n; x }
  y = 2**70 + 5
  show { y &= n; y }
  y = 2**70
  show { y |= n; y }
  y = 2**70
  show { y ^= n; y }
  show { [x, y] }
  show { $g += n; $g }
  show { $g -= sm(3, on); $g }
  show { Acc.new.add(n) }
end
p $g
