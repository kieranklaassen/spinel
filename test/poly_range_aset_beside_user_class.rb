# `x[r] = v` with a Range key on a boxed Array or String, in a program where
# a class owns `[]=`. The call goes to the class dispatch, whose default
# stored through sp_poly_set_poly with the Range boxed: an Array raised
# TypeError (no implicit conversion of Range into Integer) and a String's
# store was dropped. The same lines are right with no such class.
class Grid
  def initialize = @cells = []
  def []=(k, v)
    @cells << [k, v]
  end
  attr_reader :cells
end

def pick(i) = [[1, 2, 3, 4], +"abcdef", Grid.new, "frozen", [5, 6, 7].freeze][i]

# an Array: a local
a = pick(0)
a[1..2] = [9]
p a
a[1...1] = [7, 8]
p a
a[3..] = []
p a
p(a[0..0] = [5])
p a
a[..0] = 4
p a
begin
  a[-9..1] = [0]
rescue RangeError => e
  puts "RangeError: #{e.message}"
end
p a

# a String: a local, written back
s = pick(1)
s[1..2] = "-"
p s
s[2..] = "Z"
p s
s[..0] = "yy"
p s
p(s[-1..-1] = "!")
p s
begin
  s[9..10] = "x"
rescue RangeError => e
  puts "RangeError: #{e.message}"
end
p s

# an instance variable and an element
class Box
  def initialize
    @a = pick(0)
    @s = pick(1)
  end
  def go
    @a[0...2] = [0]
    @s[0...2] = "0"
    p @a, @s
  end
end
Box.new.go
row = [pick(0), pick(1)]
row[0][2..3] = [8, 8, 8]
p row[0]

# a shared String changes for both names
t = pick(1)
u = t
t[3..] = ""
p t, u

# the class's own `[]=` still takes a Range
g = pick(2)
g[1..2] = :v
p g.cells

# frozen receivers raise before anything is stored
begin
  f = pick(3)
  f[0..1] = "x"
rescue FrozenError => e
  puts "FrozenError: #{e.message}"
end
begin
  fa = pick(4)
  fa[0..1] = [1]
rescue FrozenError => e
  puts "FrozenError: #{e.message}"
end

# a boxed key that holds a Range
k = [1..2, 0][0]
b = pick(0)
b[k] = [3]
p b
