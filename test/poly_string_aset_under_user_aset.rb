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
