# A call with a block, as a statement, on a receiver of several classes: an
# argument is evaluated once. The dispatch splices one arm a class, and the
# statements an arm's arguments hoisted ran ahead of the switch, once an arm.
$c = 0
def tick; $c += 10000; 1; end
class K
  def blk(a); $c += 1; yield(a); end
  def sz(a); $c += 1; yield(a.size); end
end
class L
  def blk(a); $c += 4; yield(a + 1); end
  def sz(a); $c += 4; yield(a.size + 1); end
end
x = [K.new, L.new, nil][0]
x.blk([tick, 2][0]) { |q| $c += 10 * q }
p $c
x = [K.new, L.new, nil][1]
x.sz([tick, 2]) { |q| $c += 10 * q }
p $c
x.blk({ tick => 1 }.size) { |q| $c += 10 * q }
p $c
x.sz("s#{tick}") { |q| $c += 10 * q }
p $c
a = [K.new, L.new, nil]
2.times { |i| a[i].blk([tick, i][1]) { |q| $c += 10 * q } }
p $c
