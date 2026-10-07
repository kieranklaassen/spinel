# A method, reader or Struct member of the program's own named chunk,
# chunk_while, slice_when, slice_before or slice_after answers what it likes:
# here an each_with_index Enumerator, which yields two values a step, so a
# lone |x| takes the first and a lone |*r| both. Only the builtin's
# Enumerator yields one chunk a step; the hop in front of the block took
# every call of these names for the builtin's.

def chunk = [5, 6].each_with_index
p chunk.map { |x| x }
p chunk.map { |*r| r }
p chunk.any? { |x| x == 5 }
p chunk.flat_map { |x| [x] }

class Foo
  attr_reader :slice_before
  def initialize = @slice_before = [5, 6].each_with_index
  def slice_when = [5, 6].each_with_index
  def chunk_while(n) = [5, 6].each.with_index(n)
  def own = slice_when.map { |x| x }
  def self.chunk = [7, 8].each_with_index
end
f = Foo.new
p f.slice_when.map { |x| x }
p f.slice_when.map { |*r| r }
p f.chunk_while(1).map { |x| x }
p f.slice_before.map { |x| x }
p f.own
p Foo.chunk.map { |x| x }

P = Struct.new(:slice_after)
q = P.new([7, 8].each_with_index)
p q.slice_after.map { |x| x }

# the same object where the receiver's class is not settled
b = [f, 0][ARGV.size]
p b.slice_when.map { |x| x }
p b.slice_when.any? { |x| x == 5 }

# a builtin reopened with the name
class Hash
  def chunk = each_with_index
end
p({ 5 => 6 }.chunk.map { |x| x })

# the builtin's own still yield one chunk a step, beside all of the above
a = [1, 2, 4, 9, 10]
p a.chunk_while { |x, y| y == x + 1 }.map { |x| x }
p a.slice_when { |x, y| y > x + 1 }.map { |*r| r }
p a.slice_when { |x, y| y > x + 1 }.map(&:sum)
p a.chunk { _1.odd? }.map { |*r| r }
p (1..6).slice_before { _1 > 4 }.map(&:size)
v = [a, 0][ARGV.size]
p v.slice_when { |x, y| y > x + 1 }.map { |x| x }
p v.slice_when { |x, y| y > x + 1 }.map { |*r| r }
p v.chunk_while { |x, y| y == x + 1 }.map(&:sum)
