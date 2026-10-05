# A `&.` call with a block on a nil receiver answers nil and runs nothing:
# not its arguments, not the method, not the block. The yielding method is
# spliced at the call, and the splice bound self to the receiver without
# looking at the operator, so a nil receiver ran the body (and a body that
# reads an instance variable read it through NULL).
$log = []
def lg(x) = ($log << x; x)

class K
  def initialize(v = 3) = @v = v
  def each_n(n) = n.times { |i| yield i }
  def sum_n(n)
    t = @v
    n.times { |i| t += yield(i) }
    t
  end
  def name_of = "k#{yield @v}"
  def big? = yield(@v) > 2
  def pick = (yield @v) ? self : nil
  def twice
    yield @v
    yield @v + 1
    nil
  end
  def half = (yield @v) * 1.5
  def pair = [yield(@v), 2]
  def sym = yield(@v) > 0 ? :pos : :neg
  def with_kw(a, k: 2) = yield(a + k)
  def opt(a = lg(7)) = yield(a)
  def call_it(&b) = b.call(@v)
end
def mk(v) = v ? K.new : nil

# the miner's shape: an argument, the method and the block all ran
o = mk(false)
r = o&.each_n(lg(2)) { |i| lg(i + 10) }
p r, $log
o&.each_n(lg(2)) { |i| lg(i + 10) }
p $log

# each kind of answer, nil receiver then a receiver
[false, true].each do |live|
  $log = []
  o = mk(live)
  p o&.sum_n(lg(2)) { |i| lg(i) + 1 }
  p o&.name_of { |v| lg(v) }
  p o&.big? { |v| lg(v) }
  p (o&.pick { |v| lg(v) > 0 }).nil?
  p o&.twice { |v| lg(v) }
  p o&.half { |v| lg(v) }
  p o&.pair { |v| lg(v) }
  p o&.sym { |v| lg(v) }
  p o&.with_kw(lg(1), k: lg(3)) { |x| lg(x) }
  p o&.opt { |x| lg(x) }
  p o&.call_it { |v| lg(v) + 1 }
  p $log
end

# as a statement, with a local the block and the argument write
$log = []
n = 0
o = mk(false)
o&.each_n(n += 2) { |i| n += 10 }
p n
o = mk(true)
o&.each_n(n += 2) { |i| n += 10 }
p n

# the receiver runs once, either way
def mk2(x) = (lg(x); x > 0 ? K.new : nil)
p mk2(0)&.sum_n(lg(2)) { |i| lg(i + 10) }
p mk2(1)&.sum_n(lg(2)) { |i| lg(i + 10) }
p $log

# break, next and return in the block
$log = []
def run(o)
  o&.each_n(3) { |i| next if i == 1; lg(i) }
  o&.each_n(3) { |i| return :early if i == 1; lg(i + 20) }
  :done
end
p run(mk(false)), $log
p run(mk(true)), $log
o = mk(false)
p o&.sum_n(2) { |i| break 7 if i > 0; 1 }
o = mk(true)
p o&.sum_n(2) { |i| break 7 if i > 0; 1 }

# where the answer goes: a test, `||`, an argument, an interpolation, a chain
$log = []
def f(a, b) = [a, b]
[false, true].each do |live|
  o = mk(live)
  puts(o&.sum_n(1) { |i| lg(1) } ? "yes" : "no")
  p o&.sum_n(1) { |i| lg(1) } || 42
  p o&.name_of { |v| lg(v) } || "none"
  p f(o&.sum_n(1) { |i| lg(2) }, lg(9))
  p "a#{o&.sum_n(1) { |i| lg(4) }}b"
  p o&.sum_n(1) { |i| 1 }&.succ
  p [o&.sum_n(1) { |i| lg(1) }, o&.name_of { |v| lg(v) }]
end
p $log

# an instance variable's receiver, inside a method that yields itself
class W
  def initialize(k) = @k = k
  attr_reader :k
  def each_k = @k&.each_n(2) { |x| yield x + 100 }
  def go = @k&.sum_n(lg(2)) { |i| lg(i) }
end
$log = []
W.new(mk(false)).each_k { |x| lg(x) }
p $log
W.new(mk(true)).each_k { |x| lg(x) }
p $log
p W.new(mk(false)).go, W.new(mk(true)).go
w = W.new(mk(false))
p w.k&.sum_n(1) { |i| lg(5) }
w = W.new(mk(true))
p w.k&.sum_n(1) { |i| lg(5) }
p $log

# a proc handed with `&`, and a block that raises
$log = []
pr = proc { |i| lg(i) + 1 }
o = mk(false)
p o&.sum_n(2, &pr)
v = begin
  o&.sum_n(1) { |i| raise "x" }
rescue
  -1
end
p v
o = mk(true)
p o&.sum_n(2, &pr)
v = begin
  o&.sum_n(1) { |i| raise "x" }
rescue
  -1
end
p v
p $log

# in a loop, the receiver nil every other turn
$log = []
i = 0
while i < 4
  o = mk(i.odd?)
  p o&.sum_n(2) { |j| lg(i * 10 + j) }
  i += 1
end
p $log
