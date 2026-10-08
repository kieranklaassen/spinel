# A `next` in a chunk_while or slice_when block over an Integer Array or
# Range answers the block with its value. The walk read it as its own
# `continue`, which keeps the run going whatever the value.
a = [1, 2, 4, 9, 10, 12]
p a.slice_when { |x, y| next true if y == x + 1; false }.to_a
p a.chunk_while { |x, y| next false if y == x + 1; true }.to_a
p a.chunk_while { |x, y| next if y == x + 1; true }.to_a
p a.slice_when { |x, y| next y > x + 1 if y > 4; false }.to_a
p a.chunk_while { |x, y| next y == x + 1 if y > 4; true }.to_a

# an Integer and a String are true
p a.slice_when { |x, y| next 0 if y == x + 1; false }.to_a
p a.slice_when { |x, y| next "s" if y == x + 1; nil }.to_a

# a local of the block, two nexts, an unless, a case
p a.chunk_while { |x, y| t = y - x; next t == 1 if t < 3; false }.to_a
p a.slice_when { |x, y| next true if y == x + 1; next false if y > 9; y > 4 }.to_a
p a.slice_when { |x, y| next true unless y == x + 1; false }.to_a
p a.slice_when { |x, y| case y - x when 1 then next true end; false }.to_a

# the other readers of the runs
p a.slice_when { |x, y| next true if y == x + 1; false }.map { |r| r.size }
a.chunk_while { |x, y| next false if y == x + 1; true }.each { |r| p r }
p a.slice_when { |x, y| next true if y == x + 1; false }.count
puts a.slice_when { |x, y| next true if y == x + 1; false }.to_a.inspect

# a Range, and in a method
p (1..6).slice_when { |x, y| next true if y == 4; false }.to_a
p (1..6).chunk_while { |x, y| next false if y == 4; true }.to_a
def runs(a) = a.chunk_while { |x, y| next false if y > x + 1; true }.to_a
p runs([1, 2, 4, 5, 9])

# the nexts the walk already answered: a value that keeps the run, and a
# next that is the block's last expression
p a.chunk_while { |x, y| next true if y == x + 1; false }.to_a
p a.slice_when { |x, y| next false if y == x + 1; true }.to_a
p a.slice_when { |x, y| next y > x + 1 }.to_a
p a.chunk_while { |x, y| if y == x + 1 then next true else next false end }.to_a

# under a begin the walk's `continue` also left the rescue's frame, and a
# raise after the walk went uncaught: there every next is answered
begin
  p a.chunk_while { |x, y| next true if y == x + 1; false }.to_a
  p a.slice_when { |x, y| next false if y == x + 1; true }.to_a
  raise "late"
rescue => e
  puts "rescued #{e.message}"
end
