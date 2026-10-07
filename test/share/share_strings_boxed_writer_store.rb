# Flag-only: without the flag the append through the box is dropped.
# A String written through a writer whose receiver is one of several
# classes goes into the slot as its handle, and the store's own right-hand
# side makes that handle. The write barrier ran before it: a collection the
# handle caused dropped the barrier's record, and the handle was freed
# while the slot held it.
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
30.times { |i| x = mk("l" * (i % 2 + 1)); x.r = "s" + i.to_s; keep << x }
keep.each { |x| x.r << "!" }
p keep.map { |x| x.r }.join
