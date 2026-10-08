# A Range, a Rational, a Complex and a Time are kept by value, and a boxed
# slot takes one copied into a new cell. Two more callers handed that cell
# on with nothing holding it: a Struct's or a Data's `new` beside a second
# member built in the list (either allocation collects the other), and a
# call on a receiver of several classes (two such arguments, one beside a
# rest or a default built in the list, or one into a method that keeps its
# parameter in a cell).
P = Struct.new(:a, :b)
P.new(7, 7)

# a plain run: one of 2,000 Structs held another turn's number
keep = []
n = 0
while n < 2000
  r = Rational(n + 1, 3)
  q = Rational(n + 2, 5)
  keep << P.new(r, q)
  n += 1
end
bad = 0
keep.each_with_index do |s, i|
  bad += 1 unless s.a == Rational(i + 1, 3) && s.b == Rational(i + 2, 5)
end
p bad

r1 = (1..4)
r2 = ("a".."c")
r3 = (1.5..2.5)
r4 = Rational(2, 3)
r5 = Complex(1, 2)
r6 = Time.at(5)

# a Struct and a Data: one member, two, keywords, an argument that ran
# first, a call beside the read
P1 = Struct.new(:a)
P1.new(7)
D = Data.define(:a, :b)
D.new(a: 7, b: 7)
p P1.new(r4).a, P1.new(r6).a.to_i
p P.new(r1, r4).to_a, P.new(r5, 1).to_a, P.new("a" * 2, r4).to_a
p P.new(r2, r3).to_a.map { |x| [x.first, x.last] }
p D.new(r4, r1).to_h.values, D.new(a: r5, b: r4).to_h.values
count = [0]
p P.new((count[0] += 1; r4), (count[0] += 1; r1)).to_a, count
def cnt(n) = [n, n + 1].size + n
p P.new(r4, cnt(1)).to_a, P.new(cnt(1), r5).to_a

# a receiver of several classes: positionals, keywords, a class method, a
# rest or a default beside the read, a captured parameter
class K
  def m(a, v) = [a, v]
  def kw(a:, b:) = [a, b]
  def rs(a, *r) = [a, r]
  def opt(a, b = "x" * 2) = [a, b]
  def kd(a:, b: "x" * 2) = [a, b]
  def pk(a, b: "x" * 2) = [a, b]
  def cap(v) = -> { [v, 1] }
  def self.mk(a, v) = [a, v]
end
class L
  def m(a, v) = [v, a]
  def kw(a:, b:) = [b, a]
  def rs(a, *r) = [r, a]
  def opt(a, b = "y" * 2) = [b, a]
  def kd(a:, b: "y" * 2) = [b, a]
  def pk(a, b: "y" * 2) = [b, a]
  def cap(v) = -> { [2, v] }
  def self.mk(a, v) = [v, a]
end
os = [K.new, L.new]
os[0].m(7, 7)
os[0].kw(a: 7, b: 7)
os[0].rs(7, 7)
os[0].opt(7)
os[0].kd(a: 7)
os[0].pk(7)
none = {}
os[0].cap(7)
[K, L][0].mk(7, 7)
os.each do |o|
  p o.m(r4, r1), o.m(r5, 1), o.m("a" * 2, r4)
  p o.kw(a: r4, b: r5)
  p o.rs(r1, 1, 2), o.cap(r4).call
  p o.opt(r4), o.kd(a: r1), o.pk(r5, **none)
end
[K, L].each { |k| p k.mk(r1, r4) }
