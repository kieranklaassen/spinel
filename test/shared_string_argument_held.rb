# A String with a second name that appends to it is read through a copy
# where it is an argument. The copy is held while something else of the call
# is made: a second such copy, another argument's value, the Array a rest
# parameter receives.
def two(a, b) = a + b
def three(a, n, b) = a + n.to_s + b
def four(a, b, c, d) = a + b + c + d
def opt(a, b, c = "!") = a + b + c
def km(a, b:) = a + b
def rest(a, *r) = a + r.size.to_s
def pair(a, b)
  return a, b
end
def mk(x) = x + "y"
class K
  def two(a, b) = a + b
  def self.cm(a, b) = b + a
  def [](a, b) = a + b
end

s = +"base"
t = s
t << "a"
u = +"x"
v = u
v << "y"
w = "x"

# two copies, or one beside a value made in the argument list
p two(s, u)
p two(s, s)
p three(s, mk(w).size, u)
p four(w, u, w, u)
p opt(s, u)
p pair(s, u)
p send(:two, s, u)
p two(two(s, u), two(u, s))
p "<#{two(s, u)}>"
1.times { p two(s, u) }

# the Array of a rest parameter
p rest(s, 1, 2)
p rest(s, u)

# a method called on an object
k = K.new
p k.two(s, u)
p k.two(s, mk(w))
p K.new.two(s, mk(w))
p K.cm(s, u)
p k[s, u]

# instance variables
class H
  def initialize
    @s = +"base"
    t = @s
    t << "a"
    @u = +"x"
    v = @u
    v << "y"
  end
  def two(a, b) = a + b
  def run
    p two(@s, @u)
    p K.new.two(@s, @u)
    p km(@s, b: @u)
  end
end
H.new.run

# one beside plain arguments, and the Strings themselves afterwards
p two(s, w), two(w, u), three(s, 3, w)
t << "!"
p two(s, u), s, u

# long enough for the collector to run by itself
class N
  def two(a, b) = a.size + b.size + a.getbyte(0)
end
n = N.new
bad = 0
i = 0
while i < 200_000
  bad += 1 unless n.two(s, mk(w)) == 106
  i += 1
end
p bad
