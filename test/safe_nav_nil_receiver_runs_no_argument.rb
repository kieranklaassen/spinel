# A `&.` call on a nil receiver runs none of its arguments.
$log = []
def lg(x) = ($log << x; x)

class K
  attr_accessor :v
  def initialize = (@v = 0)
  def m(a) = a
  def m2(a, b) = [a, b]
  def kw(a, k: 0) = [a, k]
end
def mk(v) = v ? K.new : nil
def str(v) = v ? "ab" : nil
def ary(v) = v ? [1, 2] : nil
def hsh(v) = v ? {a: 1} : nil
def int(v) = v ? 4 : nil
def flt(v) = v ? 1.5 : nil

# a method of the program's, receiver nil
o = mk(false)
n = 0
o&.m(n += 1)
p n
p o&.m(lg(1)), $log
p o&.m2(lg(1), lg(2)), $log
p o&.kw(lg(1), k: lg(2)), $log
p o&.m((n = 7)), n
x = o&.m(lg(3)); p x, $log
p [lg(0), o&.m(lg(1)), lg(2)], $log; $log.clear
p "#{o&.m(lg(1))}", $log
p o&.m(lg(1))&.m(lg(2)), $log

# the same receiver, not nil: every argument once, in order
o = mk(true)
p o&.m(lg(1)), $log; $log.clear
p o&.m2(lg(1), lg(2)), $log; $log.clear
p o&.kw(lg(1), k: lg(2)), $log; $log.clear
p o&.m(lg(1))&.succ, $log; $log.clear
n = 0; o&.m(n += 1); p n

# builtins, receiver nil
s = str(false)
p s&.rjust(lg(5)), $log
p s&.rjust(lg(5), lg("b")), $log
p s&.center(lg(5), lg("b")), $log
p s&.sub(lg("a"), lg("b")), $log
p s&.tr(lg("a"), lg("b")), $log
p s&.+(lg("b")), $log
p s&.[](lg(0), lg(1)), $log
a = ary(false)
p a&.fetch(lg(0), lg(9)), $log
p a&.push(lg(0), lg(1)), $log
p a&.first(lg(1)), $log
p a&.map { |e| lg(e) }, $log
h = hsh(false)
p h&.fetch(lg(:a), lg(0)), $log
p h&.store(lg(:b), lg(2)), $log
i = int(false)
p i&.+(lg(1)), $log
f = flt(false)
p f&.round(lg(1)), $log

# builtins, receiver not nil
s = str(true)
p s&.rjust(lg(5), lg("b")), $log; $log.clear
p s&.sub(lg("a"), lg("b")), $log; $log.clear
a = ary(true)
p a&.fetch(lg(0), lg(9)), $log; $log.clear
p a&.push(lg(0), lg(1)), $log; $log.clear
h = hsh(true)
p h&.fetch(lg(:a), lg(0)), $log; $log.clear
i = int(true)
f = flt(true)
p f&.clamp(lg(1.0), lg(2.0)), $log; $log.clear

# a value of several classes
v = [nil, "ab", 3][ARGV.size]
p v&.to_s&.rjust(lg(5), lg("b")), $log
