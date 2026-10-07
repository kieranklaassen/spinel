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
r1 = o&.m(lg(1)); p r1, $log
r2 = o&.m2(lg(1), lg(2)); p r2, $log
r3 = o&.kw(lg(1), k: lg(2)); p r3, $log
r4 = o&.m((n = 7)); p r4, n
x = o&.m(lg(3)); p x, $log
r5 = "#{o&.m(lg(1))}"; p r5, $log
r6 = o&.m(lg(1))&.m(lg(2)); p r6, $log

# the same receiver, not nil: every argument once, in order
o = mk(true)
r7 = o&.m(lg(1)); p r7, $log; $log.clear
r8 = o&.m2(lg(1), lg(2)); p r8, $log; $log.clear
r9 = o&.kw(lg(1), k: lg(2)); p r9, $log; $log.clear
r10 = o&.m(lg(1))&.succ; p r10, $log; $log.clear
n = 0; o&.m(n += 1); p n

# builtins, receiver nil
s = str(false)
r11 = s&.rjust(lg(5)); p r11, $log
r12 = s&.rjust(lg(5), lg("b")); p r12, $log
r13 = s&.center(lg(5), lg("b")); p r13, $log
r14 = s&.sub(lg("a"), lg("b")); p r14, $log
r15 = s&.tr(lg("a"), lg("b")); p r15, $log
r16 = s&.+(lg("b")); p r16, $log
r17 = s&.[](lg(0), lg(1)); p r17, $log
a = ary(false)
r18 = a&.fetch(lg(0), lg(9)); p r18, $log
r19 = a&.push(lg(0), lg(1)); p r19, $log
r20 = a&.first(lg(1)); p r20, $log
r21 = a&.map { |e| lg(e) }; p r21, $log
h = hsh(false)
r22 = h&.fetch(lg(:a), lg(0)); p r22, $log
r23 = h&.store(lg(:b), lg(2)); p r23, $log
i = int(false)
r24 = i&.+(lg(1)); p r24, $log
f = flt(false)
r25 = f&.round(lg(1)); p r25, $log

# builtins, receiver not nil
s = str(true)
r26 = s&.rjust(lg(5), lg("b")); p r26, $log; $log.clear
r27 = s&.sub(lg("a"), lg("b")); p r27, $log; $log.clear
a = ary(true)
r28 = a&.fetch(lg(0), lg(9)); p r28, $log; $log.clear
r29 = a&.push(lg(0), lg(1)); p r29, $log; $log.clear
h = hsh(true)
r30 = h&.fetch(lg(:a), lg(0)); p r30, $log; $log.clear
i = int(true)
f = flt(true)
r31 = f&.clamp(lg(1.0), lg(2.0)); p r31, $log; $log.clear

# a value of several classes
v = [nil, "ab", 3][ARGV.size]
r32 = v&.to_s&.rjust(lg(5), lg("b")); p r32, $log
