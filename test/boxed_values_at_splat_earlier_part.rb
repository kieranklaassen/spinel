# The list of indexes of values_at on a boxed receiver is built ahead of the
# statement that holds the call, and a splat's operand is read there. What
# the statement runs before the call comes after that read: an
# interpolation, an earlier value of a multiple assignment, the index or
# the receiver of a store, the left side of an operator, an earlier value
# of a return. Where one of those can change the operand the splat is read
# as it was, an Array or nothing: nil then splats to none, and so does a
# Range that was emptied.

class Box
  attr_accessor :v
end
a = [[10, 20, 30], nil][ARGV.size]
h = [{ 1 => 5, 2 => 6 }, nil][ARGV.size]
hk = [{ a: 1, b: 2 }, nil][ARGV.size]
$r = (1..2)
$j = 1
$k = :b

# a local the statement assigns
j = 1
puts "#{j = nil}#{a.values_at(*j)}"
j = 1
x, y = (j = nil), a.values_at(*j)
p x, y
j = 1
xs = [0, 0]
xs[(j = nil; 0)] = a.values_at(*j)
p xs

# a global a method assigns
def setj = ($j = nil; 7)
def setja = ($j = nil; [7])
puts "#{setj} #{a.values_at(*$j)}"
$j = 1
u, v = setj, a.values_at(*$j)
p u, v
$j = 1
ys = [0, 0]
ys[setj - 7] = a.values_at(*$j)
p ys
$j = 1
p setja + a.values_at(*$j)
$j = 1
z = "#{setj}" + a.values_at(*$j).to_s
p z
$j = 1
p setja + h.values_at(*$j)
$j = 1
o = [Box.new]
o[setj - 7].v = a.values_at(*$j)
p o[0].v
def both(a)
  $j = 1
  return setj, a.values_at(*$j)
end
p both(a)

# a Range in a global
def setr = ($r = (2..1); [7])
p setr + a.values_at(0, *$r)

# an instance variable
class Run
  def initialize = @j = 1
  def setj = (@j = nil; [7])
  def go(a) = setj + a.values_at(*@j)
end
p Run.new.go(a)

# a later part of the statement runs after the call, and the operand is
# what it was before
$j = ARGV.size == 0 ? nil : 1
def onej = ($j = 1; 7)
p [a.values_at(*$j), onej]
k = ARGV.size == 0 ? nil : 1
p [a.values_at(*k), (k = 1; 7)]

# where nothing of the statement runs ahead of the call, or nothing in it
# can change the operand, the splat gives what it holds
p hk.values_at(*$k)
$r = (1..2)
w = a.values_at(0, *$r)
p w
m = (0..1)
puts "#{setj}#{a.values_at(*m)}"
s, t = setj, a.values_at(*(0..1))
p s, t
p setja + a.values_at(*2)
