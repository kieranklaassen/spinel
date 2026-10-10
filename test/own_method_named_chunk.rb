# A method of the program's own named chunk, chunk_while, slice_when,
# slice_before or slice_after answers what it likes: here an each_with_index
# Enumerator, which yields two values a step, so a lone |x| takes the first
# and a lone |*r| both. Only the builtin's Enumerator yields one chunk a
# step; the hop in front of the block took every call of these names for
# the builtin's. Each name is given once: that is what the proof asks.

def slice_after = [5, 6].each_with_index
p slice_after.map { |x| x }
p slice_after.map { |*r| r }
p slice_after.any? { |x| x == 5 }
p slice_after.flat_map { |x| [x] }
p slice_after.count { |*r| r.size == 2 }
p slice_after.uniq { |x| x }

class Foo
  def slice_when = "aba".each_char
  def chunk_while(n) = [5, 6].each.with_index(n)
  def own = chunk_while(0).map { |x| x }
  def self.slice_before = [7, 8].each_with_index
end
f = Foo.new
p f.chunk_while(1).map { |x| x }
p f.chunk_while(1).map { |*r| r }
p f.chunk_while(2).none? { |x| x == 5 }
p f.own
p Foo.slice_before.map { |x| x }

# a builtin reopened with the name, called with no block
class Hash
  def chunk = each_with_index
end
p({ 5 => 6 }.chunk.map { |x| x })

# a lone parameter that takes its value apart is a lone |x|, and block-locals
# leave the shape as it is
p slice_after.map { |(a, b)| [a, b] }
p slice_after.uniq { |(a, b)| b }
p slice_after.count { |x; y| y = x; y == 5 }
p slice_after.uniq { |x; y| y = x.to_s[-2]; y }
p f.chunk_while(1).none? { |*r; y| y = r; y.size == 2 }

# the name is read as the program's own only over an iterator and a block
# master answers right under any other name; the rest keep their reading
p f.slice_when.map { |*r| r }
p f.slice_when.uniq { |*r| r[0] }
slice_after.each_entry { |x| p x }

# another receiver keeps the builtin's: a Range
p (1..6).chunk { |x| x > 3 }.map { |*r| r }

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
