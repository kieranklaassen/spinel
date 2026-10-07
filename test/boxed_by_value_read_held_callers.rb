# A Range, a Rational, a Complex and a Time are kept by value, and a boxed
# slot takes one copied into a new cell. Three more callers handed that
# cell on with nothing holding it: a Struct's or a Data's `new` (the object
# is allocated before its members are stored), a proc's `call` (the body
# takes its parameters out of the call's slots and roots none) and a call
# on a receiver of several classes (each arm boxes for its own method).
P = Struct.new(:a, :b)
P.new(7, 7)
F = ->(a, b) { [a, b] }
F.call(7, 7)

# a plain run: one of the lambda's 2,000 answers held another turn's number
keep = []
n = 0
while n < 2000
  r = Rational(n + 1, 3)
  q = Rational(n + 2, 5)
  keep << F.call(r, q)
  n += 1
end
bad = 0
keep.each_with_index { |v, i| bad += 1 unless v[0] == Rational(i + 1, 3) && v[1] == Rational(i + 2, 5) }
p bad

# a plain run: so did one of 2,000 Structs
keep = []
n = 0
while n < 2000
  r = Rational(n + 1, 3)
  q = Rational(n + 2, 5)
  keep << P.new(r, q)
  n += 1
end
bad = 0
keep.each_with_index { |s, i| bad += 1 unless s.a == Rational(i + 1, 3) && s.b == Rational(i + 2, 5) }
p bad

r1 = (1..4)
r2 = ("a".."c")
r3 = (1.5..2.5)
r4 = Rational(2, 3)
r5 = Complex(1, 2)
r6 = Time.at(5)

# a Struct and a Data: one member, two, keywords, an argument that ran first
P1 = Struct.new(:a)
P1.new(7)
D = Data.define(:a, :b)
D.new(a: 7, b: 7)
p P1.new(r4).a, P1.new(r6).a.to_i
p P.new(r1, r4).to_a, P.new(r5, 1).to_a, P.new("a" * 2, r4).to_a
p P.new(r2, r3).to_a.map { |x| [x.first, x.last] }
p D.new(r4, r1).to_h.values, D.new(a: r5, b: r4).to_h.values
count = [0]
p P.new(r4, (count[0] += 1; r1)).to_a, count

# a proc: call, the dot, [] and yield; one argument and a captured one
G = ->(a) { [a, [1]] }
G.call(7)
H = ->(a) { -> { [a] } }
H.call(7)
p F.call(r4, r1), F.(r5, r4), F[r1, r5], F.yield(r4, r5)
p G.call(r4), G.call(r6)[0].to_i, H.call(r5).call
pr = proc { |a, b| [b, a] }
pr.call(7, 7)
p pr.call(r1, r4)
# the proc is one of two in a slot, or shares the slot with a class's `call`
class Caller; def call(a, b) = [a, b, 0]; end
Caller.new.call(7, 7)
[F, pr].each { |f| p f.call(r4, r5) }
[Caller.new, pr].each { |f| p f.call(r1, r4) }

# a receiver of several classes: positionals, keywords, a class method
class K
  def m(a, v) = [a, v]
  def kw(a:, b:) = [a, b]
  def self.mk(a, v) = [a, v]
end
class L
  def m(a, v) = [v, a]
  def kw(a:, b:) = [b, a]
  def self.mk(a, v) = [v, a]
end
os = [K.new, L.new]
os[0].m(7, 7)
os[0].kw(a: 7, b: 7)
[K, L][0].mk(7, 7)
os.each do |o|
  p o.m(r4, r1), o.m(r5, 1), o.m("a" * 2, r4)
  p o.kw(a: r4, b: r5)
end
[K, L].each { |k| p k.mk(r1, r4) }
