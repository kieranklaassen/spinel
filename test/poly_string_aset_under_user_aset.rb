# A user class that owns []= must not change what a genuine String does when
# it reaches the call boxed: the index assignment changes the String, as it
# does in a program with no such class. Whether the class is ever built or
# not. The assignment was dropped: the String kept its old contents.
class Grid
  def initialize = @cells = {}
  def []=(k, v)
    @cells[k] = v
  end
  def cells = @cells.to_a
end

# a local, by an Integer index, a negative one, one in a variable, a Range
row = ["name", 3]
s = row[0].dup
s[0] = "N"
p s
s[-1] = "E"
p s
i = 1
s[i] = "AA"
p s
s[1..2] = "a"
p s
s[1...-1] = ""
p s

# an element, a nested one, an element of a boxed Array: stored back in place
a = ["abc".dup, 1]
a[0][0] = "q"
p a
j = 0
a[j][2] = "r"
p a
n = [["abc".dup, 1], 2]
n[0][0][1] = "s"
p n
o = [["abc".dup, 1], 3][0]
o[0][0] = "t"
p o

# a Hash's value, a String two names hold
h = { title: +"draft", n: 1 }
h[:title][0] = "D"
p h[:title]
u = [+"shared", 1][0]
v = u
u[0] = "S"
p u, v

# an instance variable, a parameter, a block parameter
class Note
  def initialize = @text = [+"memo", 1][0]
  def cap
    @text[0] = "M"
    @text
  end
end
p Note.new.cap
def cap(x)
  x[0] = "P"
  x
end
p cap([+"param", 1][0])
[[+"block", 1][0]].each do |w|
  w[0] = "B"
  p w
end

# the assignment's value is the value assigned; key and value run once
k = [+"value", 1][0]
r = (k[0] = "V")
p r, k
c = 0
m = [+"once", 1][0]
m[(c += 1)] = (c += 10; "N")
p m, c

# an index past the end and a frozen String raise
e = [+"abc", 1][0]
begin
  e[9] = "x"
rescue IndexError => err
  puts err.message
end
f = ["abc".freeze, 1][0]
begin
  f[0] = "x"
rescue FrozenError
  puts "frozen"
end
p e, f

# the class's own []= still runs, typed and boxed, and an Array and a Hash
# in the same slot still store
g = Grid.new
g[1] = 2
p g.cells
slots = [Grid.new, "abc".dup, [1, 2], { 1 => "b" }]
slots.each { |x| x[0] = "Z" }
p slots[0].cells, slots[1], slots[2], slots[3].to_a

# where the kept store would go wrong it stands down: a value that rebinds
# the receiver or moves the element's index changes no other String, and a
# boxed value that holds no String leaves the String as it was
t = [+"other", 1][0]
u = [+"first", 1][0]
u[0] = (u = t; "X")
p u, t
rows = [+"abc", +"xyz", 1]
ri = 0
rows[ri][0] = rows[ri += 1][1]
p rows[1], ri
w = [+"abc", 1][0]
bv = [7, "z"][0]
begin
  w[0] = bv
rescue TypeError
end
p w

# a key, a value or a receiver that runs the program's code with no call
# written (an interpolated object's to_s or inspect, a `when` object's ===,
# an `in` object's deconstruct) runs it once
class Tally
  def initialize; @n = 0; end
  def n = @n
  def to_s; @n += 1; "a"; end
  def inspect; @n += 1; "i"; end
  def ===(x); @n += 1; true; end
  def deconstruct; @n += 1; [1, 2]; end
end
tl = Tally.new
hs = [+"abcdef", 1][0]
hs[0] = "#{tl}"
p hs, tl.n
hs[1] = "<#{[tl]}>"
p hs, tl.n
tb = [tl, 1][0]
hs[2] = "#{tb}"
p hs, tl.n
hs[3] = (case 1 when tl then "w" else "b" end)
p hs, tl.n
hs[4] = (case tl; in [1, 2] then "d"; else "b"; end)
p hs, tl.n
hs[(case 1 when tl then 5 else 0 end)] = "k"
p hs, tl.n
hs[0..1] = "#{tl}#{1}"
p hs, tl.n
ha = [+"abcdef", 1]
ha[(case 1 when tl then 0 else 1 end)][0] = "Q"
p tl.n
ht = [+"uvwxyz", 1][0]
(case 1 when tl then hs else ht end)[0] = "R"
p tl.n
hl = [[+"abc", 1][0], [+"def", 1][0]]
hl.each_with_index { |r, x| hl[x][0] = "#{tl}" }
p tl.n

# and what such code rebinds or replaces is not stored into: an instance
# variable, an element, a local a lambda assigns
class Swap
  def initialize
    @s = [+"abcdef", 1][0]
    @t = [+"uvwxyz", 1][0]
    @a = [+"abcdef", 1]
  end
  def to_s = (@s = @t; @a[0] = @t; "X")
  def go
    @s[0] = "#{self}"
    p @s, @t
  end
  def go_slot
    @a[0][0] = "#{self}"
    p @a, @t
  end
end
Swap.new.go
Swap.new.go_slot
ls = [+"abcdef", 1][0]
lt = [+"uvwxyz", 1][0]
$rebind = -> { ls = lt }
class Rebinder
  def to_s = ($rebind.call; "X")
end
ls[0] = "#{Rebinder.new}"
p ls, lt

# an interpolation of Strings and numbers runs none
qn = 5
qs = "q"
hq = { title: +"draft", n: 1 }
hq[:title][0] = "#{qs}#{qn}"
p hq[:title]
