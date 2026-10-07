# A call with a block, as a statement, on a receiver of several classes:
# the receiver is evaluated once. The dispatch that splices one arm a class
# gave up when an arm declined, after the receiver's statements were
# written, and the call that followed ran them a second time.
$c = 0
def tick; $c += 10000; 1; end
class K
  def blk(a); $c += 1; yield(a); end
end
class K2 < K
  def blk(a); $c += 2; yield(a + 1); end
end
class L
  def blk(a, &b); $c += 4; b.call(a + 2); end
end
def mk(i); $c += 1000; [K.new, K2.new, L.new][i]; end

h = { 1 => K.new, 2 => K2.new, 3 => L.new }
h[[tick, 1][1]].blk(1) { |q| $c += 10 * q }
p $c
h[[tick, 2][1]].blk(1) { |q| $c += 10 * q }
p $c
h.fetch([tick, 3][1]).blk(tick) { |q| $c += 10 * q }
p $c
[mk(0), mk(1)][1].blk(1) { |q| $c += 10 * q }
p $c
[mk(2), mk(0)].first.blk([tick, 2][0]) { |q| $c += 10 * q }
p $c
def go(h)
  h[[tick, 1][1]].blk(1) { |q| $c += 10 * q }
  $c += 100000
end
go(h)
p $c
2.times { h.dig([tick, 2][1]).blk(1) { |q| $c += 10 * q } }
p $c
