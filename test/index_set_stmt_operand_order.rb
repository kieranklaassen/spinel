# A statement element store runs its receiver, its key, then its value
# `recv[key] = value` whose value goes nowhere was written as one C call
# with the three operands as sibling arguments, which gcc evaluates right to
# left: `a[t(1)] = t(2)` ran t(2) first, `b[i] = (i += 1; 50)` stored at the
# index the value left behind, and a Hash store whose value reassigns the
# key's variable went in under the new key. CRuby runs the receiver, the key,
# then the value, once each.
class Cell
  attr_reader :v
  def initialize(v) = @v = v
end

def t(n) = (puts "t#{n}"; n)
def s(n) = (puts "s#{n}"; "s#{n}")
def f(n) = (puts "f#{n}"; n + 0.5)
def ia(a) = (puts "ia"; a)

puts "-- Integer Array"
a = [0, 0, 0]
a[t(1)] = t(2)
ia(a)[t(0)] = t(3)
p a

puts "-- String Array"
b = ["x", "y"]
b[t(1)] = s(2)
p b

puts "-- Float Array"
g = [0.5, 1.5]
g[t(0)] = f(3)
p g

puts "-- Array of anything"
h = [0, "x", nil]
h[t(2)] = s(4)
h[t(0)] = t(5)
p h

puts "-- a closure that advances"
n = 0
nxt = -> { n += 1; n - 1 }
out = [9, 9, 9, 9]
out[nxt.call] = nxt.call
out[nxt.call] = nxt.call
p out

puts "-- a key the value reassigns"
i = 0
c = [0, 0, 0]
c[i] = (i += 1; 50)
c[i + 1] = (i -= 1; 70)
p c, i
w = ["a", "b"]
j = 1
w[j] = (j = 0; "z")
p w

puts "-- a receiver the value reassigns"
v = [1, 2]
v0 = v
v[0] = (v = [5, 5]; 6)
p v, v0
u = ["a", "b"]
u0 = u
u[(u = ["q", "q"]; 1)] = "z"
p u, u0

puts "-- a key that reads what the value shifts"
q = [2, 0, 1]
r = [0, 0, 0]
r[q[0]] = q.shift
r[q[0]] = q.shift
p r, q

puts "-- a row whose index the value moves"
def fill(n)
  m = Array.new(n) { |x| Array.new(n, x) }
  d = 0
  m[d][1] = (d += 1; 9)
  m[d][d - 1] = (d += 1; 8)
  [m[0][1], m[1][0], m[1][1], m[2][0], m[2][1], d]
end
p fill(3)

puts "-- instance variables"
class Board
  attr_accessor :cells, :mix
  attr_reader :names, :at

  def initialize
    @cells = [0, 0, 0]
    @names = ["a", "b", "c"]
    @mix = [0, "x", nil]
    @at = 0
  end

  def bump = (@at += 1; @at * 10)
  def fresh = (@cells = [8, 8, 8]; 1)
  def rename = (@names = ["n", "n", "n"]; "r")

  def run
    @cells[t(1)] = t(2)
    @names[t(0)] = s(1)
    @mix[t(2)] = s(3)
    p @cells, @names, @mix
    @cells[@at] = bump
    @cells[@at + 1] = bump
    p @cells, @at
    old = @cells
    @cells[0] = fresh
    p @cells, old
    was = @names
    @names[2] = rename
    p @names, was
  end
end
Board.new.run

puts "-- another object writes the receiver's variable back"
class Poker
  def poke(board) = (board.cells = [3, 3, 3]; 4)
end
class Board
  def poked(pk)
    old = @cells
    @cells[1] = pk.poke(self)
    p @cells, old
  end
end
pk = Poker.new
Board.new.poked(pk)

puts "-- a receiver read through its reader"
bd = Board.new
old = bd.cells
bd.cells[1] = pk.poke(bd)
p bd.cells, old
old = bd.cells
bd.cells[0] = [pk.poke(bd), 9].min
p bd.cells, old

puts "-- a method the program gives Array, called on a literal"
class Array
  def poke_all = ($board.cells = [3, 3, 3]; size + 2)
end
$board = bd
old = bd.cells
bd.cells[2] = [1, 2].poke_all
p bd.cells, old

puts "-- a comparison that runs the object's own =="
class Mover
  def initialize(board) = @board = board
  def ==(o) = (@board.mix = [9, "y", nil]; true)
end
mv = Mover.new(bd)
was = bd.mix
bd.mix[0] = (bd.cells.size == mv)
p bd.mix, was

puts "-- a variable only its constructor assigns, assigned in an operand"
class Once
  def initialize
    @a = [0, 0]
    @b = @a
    @a[0] = (@a = [5, 5]; 6)
    p @a, @b
  end
end
Once.new

puts "-- Hash: a key the value reassigns"
hh = {}
k = 0
hh[k] = (k += 1; 5)
hh[k + 1] = (k += 1; 6)
p hh.to_a, k
sh = {}
sk = "a"
sh[sk] = (sk = "b"; 1)
p sh.to_a

puts "-- Hash: a receiver the value reassigns"
hv = { 1 => 1 }
hv0 = hv
hv[2] = (hv = { 9 => 9 }; 3)
p hv.to_a, hv0.to_a

puts "-- Hash in instance variables"
class Index
  def initialize
    @h = { 9 => 9 }
    @k = 0
  end

  def bump = (@k += 1; @k * 10)
  def fresh = (@h = { 7 => 7 }; 1)

  def run
    @h[@k] = bump
    @h[@k + 1] = bump
    p @h.to_a
    old = @h
    @h[5] = fresh
    p @h.to_a, old.to_a
  end
end
Index.new.run

puts "-- a global and a class variable the value reassigns"
$ga = [1, 2]
ga0 = $ga
$ga[0] = ($ga = [5, 5]; 6)
p $ga, ga0
def regrow = ($ga = [7, 7]; 8)
ga0 = $ga
$ga[1] = regrow
p $ga, ga0
$gh = { 1 => 1 }
gh0 = $gh
$gh[2] = ($gh = { 9 => 9 }; 3)
p $gh.to_a, gh0.to_a
class Tally
  @@t = [0, 0]
  @@h = { 1 => 1 }
  def self.reset = (@@t = [4, 4]; 3)
  def self.rehash = (@@h = { 8 => 8 }; 2)

  def self.run
    old = @@t
    @@t[0] = reset
    p @@t, old
    old = @@t
    @@t[1] = (@@t = [6, 6]; 2)
    p @@t, old
    oh = @@h
    @@h[5] = rehash
    p @@h.to_a, oh.to_a
  end
end
Tally.run

puts "-- nothing to order: the same answers"
def table(n)
  tb = Array.new(n) { Array.new(n, 0) }
  x = 1
  while x < n
    tb[x][x] = [tb[x - 1][x] + 3, tb[x][x - 1] + 2, 9].min
    tb[x][0] = Math.sqrt(16.0).to_i
    x += 1
  end
  [tb[1][0], tb[1][1], tb[2][0], tb[2][2]]
end
p table(3)
cs = [Cell.new(1), Cell.new(2)]
vs = [0, 0]
vs[cs[1].v - 1] = cs[0].v + 4
p vs
