# spinel: int64
# A Bignum operation with an Integer operand that is nil. The operand's slot
# holds the nil as a sentinel; made a Bignum for the operation it was the
# NULL a Bignum slot holds, and the operation read through it.
$log = []
def lg(x) = ($log << x; x)
def sm(k, on) = on ? k : nil
def big(t) = (lg(t); 2**70)
def nn(t, on) = (lg(t); sm(3, on))
def show
  r = yield
  puts r.inspect
rescue NoMethodError
  puts "NoMethodError"
rescue => e
  puts "#{e.class}: #{e.message}"
end
class Acc
  attr_reader :v
  def initialize(v) = (@v = v; @b = 2**70)
  def add(n) = (@b += n; @b)
end
h = 2**70
[true, false].each do |on|
  n = sm(3, on)
  show { [h == n, h != n, n == h, n != h] }
  show { h < n }
  show { h >= n }
  show { n > h }
  show { h + n }
  show { h - n }
  show { h * n }
  show { h / n }
  show { h % n }
  show { n + h }
  show { n * h }
  show { h.modulo(n) }
  show { h.div(n) }
  show { h.divmod(n) }
  show { h.pow(2, n) }
  show { h.allbits?(n) }
  show { h.anybits?(n) }
  show { h.nobits?(n) }
  a = Acc.new(n)
  show { a.add(n) }
  show { h + a.v }
  show { big(1) + nn(2, on) }
  show { nn(3, on) < big(4) }
  show { big(5).divmod(nn(6, on)) }
  p $log
  $log = []
end
ia = [1, 3, 5]
hi = { "a" => 3 }
show { h + ia[9] }
show { h == hi["zz"] }
show { h <= "abcd".index("z") }
show { ia.find { |v| v > 9 } * h }
