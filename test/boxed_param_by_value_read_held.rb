# A Range, a Rational, a Complex and a Time are kept by value. One read out
# of a local, an instance variable or a constant into a parameter that is
# boxed (another call passes it an Integer) is copied into a new cell at the
# call. Nothing held that cell: the object's own allocation, a second such
# argument or the cell of a captured parameter freed it.
class Slot
  def initialize(v) = @v = v
  def v = @v
end
Slot.new(7)

# a plain run: about 1,800 turns in, one Slot held another number
keep = []
n = 0
while n < 2000
  r = Rational(n, 7)
  keep << Slot.new(r)
  n += 1
end
bad = 0
keep.each_with_index { |o, i| bad += 1 unless o.v == Rational(i, 7) }
p bad

# every kind into a constructor
r1 = (1..4)
r2 = (1...4)
r3 = ("a".."c")
r4 = (1.5..2.5)
r5 = Rational(2, 3)
r6 = Complex(1, 2)
r7 = Time.at(5)
p Slot.new(r1).v.to_a, Slot.new(r2).v.to_a, Slot.new(r3).v.to_a
p Slot.new(r4).v.end, Slot.new(r5).v, Slot.new(r6).v, Slot.new(r7).v.to_i

# two of them in one call: the second box freed the first
def pair(a, b) = [a, b]
pair(7, 7)
p pair(r5, r1), pair(r6, r5)

# keywords, and a default built beside the read
def kw(a:, b:) = [a, b]
kw(a: 7, b: 7)
p kw(a: r5, b: r6)
class Wide
  def initialize(v, w = [1])
    @v = v
    @w = w
  end
  def v = [@v, @w]
end
Wide.new(7)
p Wide.new(r5).v

# a parameter a lambda captures lives in a cell the method allocates first
def later(v) = -> { v }
later(7)
p later(r5).call, later(r1).call

# the read is an instance variable or a constant
RC = Rational(5, 7)
class Holder
  def initialize(n)
    @r = Rational(n, 3)
    @q = (1..n)
  end
  def slots = [Slot.new(@r).v, Slot.new(@q).v, Slot.new(RC).v]
end
p Holder.new(2).slots
p Slot.new(RC).v, pair(RC, r1)

# beside a read of a String a block appends to: the read copies the live
# buffer where the argument stands, and the copy collected the box
def second(a, v) = v
second("z", 7)
w = +"ab" * 40000
[1, 2].each { w << "c" }
kept = []
m = 0
while m < 3000
  q = Rational(m, 7)
  kept << second(w, q)
  m += 1
end
off = 0
kept.each_with_index { |o, i| off += 1 unless o == Rational(i, 7) }
p off
