# A Range, a Time, a Rational or a Complex stored through a writer whose
# receiver is one of several classes goes into the slot behind a heap copy.
# The write barrier ran before the copy was made: a collection the copy
# caused dropped the barrier's record, and the copy was freed while the
# slot held it.
class Span
  attr_accessor :r
  def initialize(n) = @name = n
end
class Gap
  attr_accessor :r
  def initialize(n) = @name = n
end
def mk(n) = [Span.new(n), Gap.new(n), 1][n.size % 2]

keep = []
30.times { |i| x = mk("l" * (i % 2 + 1)); x.r = (1..i); keep << x }
p keep.map { |x| x.r.last }.sum

keep = []
30.times { |i| x = mk("l" * (i % 2 + 1)); x.r = Time.at(i); keep << x }
p keep.map { |x| x.r.to_i }.sum

keep = []
30.times { |i| x = mk("l" * (i % 2 + 1)); x.r = Rational(i, 3); keep << x }
p keep.map { |x| x.r }.sum

keep = []
30.times { |i| x = mk("l" * (i % 2 + 1)); x.r = Complex(i, 3); keep << x }
p keep.map { |x| x.r.real }.sum

# the same store under `&.`, and as the last statement of a method
keep = []
30.times { |i| x = mk("l" * (i % 2 + 1)); x&.r = (2..i); keep << x }
p keep.map { |x| x.r.last }.sum

def put(x, i)
  x.r = (3..i)
end
keep = []
30.times { |i| x = mk("l" * (i % 2 + 1)); put(x, i); keep << x }
p keep.map { |x| x.r.first }.sum
