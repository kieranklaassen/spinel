# `x[a, b] = v` on a boxed receiver calls a user class's `[]=` that takes
# three arguments or a splat. It was lowered to the Array and String splice,
# which leaves an object as it was, so the store was dropped. An Array or a
# String in the same slot still takes the splice.

class Grid
  def initialize = @c = {}
  def []=(x, y, v)
    @c[[x, y]] = v
    :ignored
  end
  def [](x, y) = @c[[x, y]]
  def cells = @c.to_a
end

class Row
  def initialize = @v = {}
  def []=(x, v)
    @v[x] = v
  end
  def [](x) = @v[x]
  def vals = @v.to_a
end

class Multi
  def initialize = @log = []
  def []=(*ks, v)
    @log << [ks, v]
  end
  def log = @log
end

$log = []
def t(n) = ($log << n; n)
def w(x) = ($log << :w; x)

# a three-parameter `[]=`, the only class in the slot
g = [Grid.new, 1][0]
g[1, 2] = :cell
g[3, 4] = "s"
p g[1, 2], g[3, 4], g.cells.size

# beside a class whose `[]=` takes two
both = [Grid.new, Row.new]
both[0][1, 2] = :a
both[1][3] = :b
both.each do |o|
  if o.is_a?(Grid)
    o[5, 6] = 7
  else
    o[8] = 9
  end
end
p both[0].cells, both[1].vals

# through a method parameter: an object, a String and an Array
def put(x, v)
  x[1, 2] = v
  x
end
h = Grid.new
put(h, 7)
put([h, "s"][0], 8)
p h[1, 2], h.cells
p put(+"hello", "x")
p put([1, 2, 3, 4], [9])

# the splat form, with one key and with two
m = [Multi.new, 1][0]
m[1] = 3
m[1, 2] = 4
m[:k, "s"] = [5]
p m.log

# the value of the assignment is the value assigned
p((g[5, 6] = 11))
r = (g[7, 8] = [9])
r << 10
p g[7, 8], r
p((m[2, 3] = :v))
y = [[1, 2, 3], 1][0]
p((y[0, 2] = [8]))
p y

# each operand runs once, the receiver first
w(g)[t(1), t(2)] = t(3)
p g[1, 2], $log
$log = []
g[t(4), t(5)] = [t(6)]
p g[4, 5], $log
$log = []
i = 0
g[i, (i += 1)] = :o
p g[0, 1], i
row = [[1, 2, 3, 4], g][0]
row[i, (i += 1)] = []
p row, i
w(m)[t(1), t(2)] = t(3)
p m.log.last, $log

# a receiver read out of a slot: its index runs once, ahead of the operands
els = [Grid.new, [1, 2, 3, 4], +"hello"]
$log = []
els[t(0)][t(1), t(2)] = t(3)
els[t(1)][t(1), t(2)] = [t(3)]
els[t(2)][t(1), t(2)] = "-"
p els[0][1, 2], els[1], els[2], $log
n = -1
els[n += 1][n += 1, 1] = :p
els[n += 1][(n -= 1), 1] = "E"
p els[0][1, 1], els[2], n

# in a loop, and from an instance variable
class Board
  def initialize(x) = @x = x
  def set(a, b, v)
    @x[a, b] = v
  end
end
k = Grid.new
[k, [0, 0, 0], +"abcdef"].each { |e| Board.new(e).set(1, 2, e.is_a?(Grid) ? 5 : e.is_a?(Array) ? [4] : "-") }
p k.cells
3.times { |n| g[n, n] = n * n }
p g[0, 0], g[1, 1], g[2, 2]

# the splices and the two-parameter `[]=` are as they were
a = [[1, 2, 3, 4], 1][0]
a[1, 2] = [9]
p a
a[1, 0] = [7, 8]
p a
s = [+"hello", 1][0]
s[1, 2] = "x"
p s
rows = [[1, 2, 3], +"abc"]
rows[0][0, 1] = [5, 6]
rows[1][0, 1] = "zz"
p rows
q = [Row.new, 1][0]
q[1] = 2
q[:k] = "v"
p q.vals

# an operand the class dispatch has no temp for keeps the splice alone
class Tail
  def initialize = @c = []
  def []=(x, y, v)
    @c << v
    v << "+" if x == 1
  end
  def c = @c
end
tl = Tail.new
u = "u"
tl[0, 0] = u
z = [+"hello", 1][0]
z[1, 2] = (u = "w")
p z, u, tl.c

# a Struct's own []= takes two: with three operands CRuby raises
# ArgumentError, and the Struct is as it was
Slot = Struct.new(:a, :b)
sl = [Slot.new(1, 2), Grid.new][0]
begin
  sl[0, 1] = 5
rescue ArgumentError
end
p sl.a
