# `o&.v = x` as a statement on a nil receiver stores nothing and runs no
# part of the value; a receiver that is not nil is written once.

$log = []
def lg(x) = ($log << x; x)

class K
  attr_accessor :v, :s, :a
  attr_writer :w
  def initialize = (@v = 0; @s = "s"; @a = [0]; @w = 0)
  def w = @w
end
def mk(v) = v ? K.new : nil

# the writer of an attr_accessor
o = mk(false)
o&.v = lg(1)
p o&.v, $log
o = mk(true)
o&.v = lg(1)
p o&.v, $log

# a value that is built ahead of the store
$log = []
o = mk(false)
o&.s = "#{lg(2)}!"
o&.a = [lg(3), lg(4)]
p o&.s, o&.a, $log
o = mk(true)
o&.s = "#{lg(2)}!"
o&.a = [lg(3), lg(4)]
p o&.s, o&.a, $log

# an attr_writer
$log = []
o = mk(false)
o&.w = lg(5)
p o&.w, $log
o = mk(true)
o&.w = lg(5)
p o&.w, $log

# a Struct member
P = Struct.new(:x, :y)
def st(v) = v ? P.new(1, 2) : nil
$log = []
s = st(false)
s&.x = lg(6)
p s&.x, $log
s = st(true)
s&.x = lg(6)
p s&.x, s&.y, $log

# inside a method, on a parameter
def set(o, n) = (o&.v = lg(n); o)
$log = []
p set(mk(false), 7)&.v, set(mk(true), 8)&.v, $log

# in a loop, the receiver nil every other round
$log = []
t = 0
4.times do |i|
  o = mk(i.odd?)
  o&.v = lg(i * 10)
  t += o&.v || 0
end
p t, $log

# a writer only a subclass has
class B; def initialize = (@n = 0); end
class D < B; attr_accessor :n; end
def mkd(v) = v ? D.new : nil
$log = []
d = mkd(false)
d&.n = lg(9)
p d&.n, $log
d = mkd(true)
d&.n = lg(9)
p d&.n, $log

# a class some object of which is frozen
class F
  attr_accessor :v
  def initialize = (@v = 0)
end
def mkf(v) = v ? F.new : nil
F.new.freeze
$log = []
f = mkf(false)
f&.v = lg(11)
p f&.v, $log
f = mkf(true)
f&.v = lg(11)
p f&.v, $log

# the value of the assignment, as before
$log = []
o = mk(false)
x = (o&.v = lg(12))
p x, $log
o = mk(true)
x = (o&.v = lg(12))
p x, $log
