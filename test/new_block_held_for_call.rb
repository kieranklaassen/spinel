# A block handed to `new` is a proc built at the call site: a literal, a
# lambda, a `&` of anything that answers one. Nothing roots it there, and
# what allocates next collects it: an argument built beside it in the call,
# or the constructor's own allocation of the object.
class Agg
  def initialize(&blk)
    @blk = blk
  end
  def v = @blk.call(2)
end
class Base
  def initialize(a, *rest, &blk)
    @a = a
    @rest = rest
    @blk = blk
  end
  def v = [@a, @rest, @blk.call(2)]
  def self.plain = new(1, 2, 3) { |v| v + 7 }
end
class Kid < Base
end
class Keyed
  def initialize(a, *rest, k: 0, &blk)
    @v = [a, rest, k]
    @blk = blk
  end
  def v = [@v, @blk.call(2)]
end
class Solo
  def initialize(a, &blk)
    @a = a
    @blk = blk
  end
  def v = [@a, @blk.call(2)]
end
class Yld
  def initialize
    @v = yield(2)
  end
  def v = @v
end
class YldA
  def initialize(a)
    @v = [a, yield(2)]
  end
  def v = @v
end
def count(n) = Array.new(n) { |j| j.to_s }.size
def make(i) = proc { |v| v + i }
def dbl(v) = v * 2
def base(n) = Base.new(n, n + 1, n + 2) { |v| v + n }

i = 5
xs = [4, 5]
pr = proc { |v| v + i }
p Agg.new { |v| v + i }.v
p Agg.new(&->(v) { v + i }).v
p Agg.new(&proc { |v| v + i }).v
p Agg.new(&method(:dbl)).v
p Agg.new(&:to_s).v
p Agg.new(&make(i)).v
p Agg.new(&pr).v
p Base.new(1, 9, 7) { |v| v + i }.v
p Base.new("a" * 2, "b" * 2, "c" * 2) { |v| v + i }.v
p Base.new(1, *xs, 3) { |v| v + i }.v
p Kid.new(1, 2) { |v| v * i }.v
p Base.plain.v, base(3).v
p Keyed.new(1, 2, 3, k: 4) { |v| v + i }.v
p Keyed.new(1, 2, k: count(2)) { |v| v + i }.v
p Solo.new(count(3)) { |v| v + i }.v
p Solo.new(count(3), &->(v) { v + i }).v
p Solo.new("s" * 2, &make(i)).v
p Yld.new(&->(v) { v + i }).v
p Yld.new(&method(:dbl)).v
p Yld.new(&make(i)).v
p YldA.new(count(3), &->(v) { v + i }).v
p YldA.new("s" * 2, &->(v) { v + i }).v

kept = []
n = 0
while n < 200
  kept << base(n)
  kept << Agg.new { |v| v + n }
  n += 1
end
bad = 0
kept.each_with_index do |o, k|
  m = k / 2
  bad += 1 unless o.v == (k.even? ? [m, [m + 1, m + 2], m + 2] : 202)
end
p bad
