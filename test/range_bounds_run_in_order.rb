# A Range's first bound runs before its last, as CRuby runs them. The two
# were arguments of one C call, whose order C leaves open, and gcc ran the
# last bound first: two bounds with an effect ran in reverse, and a first
# bound read what the last had already changed.
$log = []
def li(x) = ($log << x; x)
def lf(x) = ($log << x; x)
def ls(x) = ($log << x; x)
def lg(x) = ($log << x; x)

# two bounds with an effect: Integer, exclusive, Float, mixed, String
r = (li(1)..li(4))
p r, $log
r = (li(1)...li(4))
p r, $log
$log = []
p (lf(1.5)..lf(2.5)).include?(2.0), (li(1)..lf(2.5)).include?(2), (lf(1.5)..li(4)).include?(3.5), $log
$log = []
p (ls("a")..ls("c")).to_a, (ls("a")...ls("c")).to_a, $log

# what reads the Range
$log = []
p (li(2)..li(5)).to_a, (li(2)..li(5)).size, (li(2)..li(5)).sum, $log
$log = []
p (li(2)..li(5)).include?(li(3)), (lf(1.5)...lf(2.5)).include?(2.0), $log
$log = []
(li(1)..li(3)).each { |i| li(i * 10) }
p $log
$log = []
p (li(1)..li(3)).map { |i| li(i * 10) }, $log
$log = []
(li(1)..li(7)).step(li(2)) { |i| li(i * 10) }
p $log
$log = []
p (li(1)..li(4)).select { |i| i.even? }, (li(1)..li(4)).reduce(0) { |a, i| a + i }, $log
$log = []
x = 3
case x
when li(1)..li(2) then puts "low"
when li(3)..li(4) then puts "mid"
end
p x.clamp(li(4)..li(6)), (li(1)..li(5)) === x, (li(1)..li(5)).cover?(x), $log

# a first bound the last one changes: a local, an instance variable, a
# global, a local a proc assigns
n = 3
p (n..(n = 5))
n = 3
p (n..(n = 5)).to_a
n = 3
p (n...(n += 4)).size
n = 3
p (n..lg((n = 6))).to_a
n = 3
p (n + 1..(n = 9))
n = 3
$log = []
(n..(n = 5)).each { |i| li(i) }
p $log
f = 1.5
p (f..(f = 2.5)).include?(2.0)
s = "a"
p (s..(s = "c")).to_a
class C
  def initialize = @v = 1
  def bump = (@v += 10)
  def r1 = (@v..bump)
  def r2 = (@v..bump).to_a.size
  attr_reader :v
end
c = C.new
p c.r1, c.v
p c.r2, c.v
$g = 1
def gb = ($g += 10)
p ($g..gb)
p ($g..gb).size
v = 1
la = -> { v = 50; 60 }
p (v..la.call)
v = 1
p (v..la.call).size

# where the Range goes: an argument, a container, a test, an interpolation
def mk(a, b) = (a..b)
def twice(r) = [r, r]
$log = []
p mk(li(1), li(2)), twice(li(1)..li(2)), $log
$log = []
p [(li(5)..li(6)), (li(7)...li(8))], [li(0), (li(1)..li(2)), li(3)], $log
$log = []
ok = false
p ok && (li(1)..li(2)), (ok ? (li(1)..li(2)) : (li(3)..li(4))), $log
$log = []
p "#{li(9)} #{(li(1)..li(2))}", [li(1), (li(2)..li(3)).to_a, li(4)], $log
$log = []
p (li(1)..), (..li(2)), (li(1)..nil), $log

# in a loop and a block
$log = []
i = 0
while i < 3
  p (li(i)..li(i + 2)).to_a
  i += 1
end
p [1, 2].map { |k| (li(k)..li(k + 1)).to_a }, ((li(1)..li(2)).to_a + (li(3)..li(4)).to_a), $log
