# `o&.tap { }` and `o&.then { }` on a nil receiver answer nil and run no
# block; a receiver that is not nil runs it once.

$log = []
def lg(x) = ($log << x; x)
class K
  attr_accessor :v
  def initialize = (@v = 7)
end
def mk(v) = v ? K.new : nil
def str(v) = v ? "ab" : nil
def ary(v) = v ? [1, 2] : nil
def int(v) = v ? 4 : nil
def hsh(v) = v ? {a: 1} : nil

$log = []
o = mk(false)
p o&.tap { |x| lg(1) }&.v, $log
$log = []
o = mk(true)
p o&.tap { |x| lg(1) }&.v, $log
$log = []
o = mk(false)
p o&.then { |x| lg(1) }, $log
$log = []
o = mk(true)
p o&.then { |x| lg(x.v) }, $log
$log = []
o = mk(false)
o&.tap { |x| lg(1) }
p $log
$log = []
o = mk(true)
o&.tap { |x| lg(x.v) }
p $log
$log = []
o = mk(false)
o&.then { |x| lg(1) }
p $log
$log = []
o = mk(true)
o&.then { |x| lg(x.v) }
p $log
$log = []
s = str(false)
p s&.then { |x| lg(x + "!") }, $log
$log = []
s = str(true)
p s&.then { |x| lg(x + "!") }, $log
$log = []
s = str(false)
p s&.tap { |x| lg(x.size) }, $log
$log = []
s = str(true)
p s&.tap { |x| lg(x.size) }, $log
$log = []
a = ary(false)
p a&.then { |x| lg(x.sum) }, $log
$log = []
a = ary(true)
p a&.then { |x| lg(x.sum) }, $log
$log = []
a = ary(false)
p a&.tap { |x| lg(x.size) }, $log
$log = []
a = ary(true)
p a&.tap { |x| lg(x.size) }, $log
$log = []
i = int(false)
p i&.then { |x| lg(x * 2) }, $log
$log = []
i = int(true)
p i&.then { |x| lg(x * 2) }, $log
$log = []
i = int(false)
p i&.tap { |x| lg(x) }, $log
$log = []
i = int(true)
p i&.tap { |x| lg(x) }, $log
$log = []
h = hsh(false)
p h&.then { |x| lg(x.size) }, $log
$log = []
h = hsh(true)
p h&.then { |x| lg(x.size) }, $log
$log = []
o = mk(false)
p o&.yield_self { |x| lg(1) }, $log
$log = []
o = mk(false)
x = o&.then { |k| lg(k.v) } || 0
p x, $log
$log = []
o = mk(true)
x = o&.then { |k| lg(k.v) } || 0
p x, $log
$log = []
o = mk(false)
p o&.then { |x| [lg(1), lg(2)] }, $log
$log = []
o = mk(true)
p o&.then { |x| [lg(1), lg(2)] }, $log
$log = []
o = mk(false)
p o&.tap { |x| x.v = lg(3) }&.v, $log
$log = []
o = mk(true)
p o&.tap { |x| x.v = lg(3) }&.v, $log
$log = []
o = mk(true)
p o.tap { |x| lg(1) }.v, o.then { |x| lg(2) }, $log
