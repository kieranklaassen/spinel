# A bare target after an Array pattern's splat takes an element whose class
# the Array's type does not tell: an Array of Symbols, of true and false, of
# Arrays or of a mix holds boxed elements. A local that an assignment also
# writes kept the assignment's type, and the element was read at that type:
# a String local took a Symbol's bits and the program crashed, and an Array
# read as a String printed memory.

# an Array of Symbols into a String local
t = "o"
case [:q, :r]
in [_, *, t]
  p t
end
p t

# an Array of Arrays
u = "o"
case [[1], [2]]
in [*, u]
  p u
end
puts "#{u} #{u.class}"

# true and false, nil, a Hash, a Range, an object of the program's own class
class Pt
  def initialize(v) = (@v = v)
  def inspect = "#<Pt #{@v}>"
  def to_s = "pt#{@v}"
end
b = 0
case [true, false]
in [*, b, _]
  p b
end
n = 2.5
case [1, nil]
in [*, n]
  p n
end
puts "nil" if n.nil?
h = :o
case [{a: 1}, {b: 2}]
in [*, h]
  puts h.class
end
r = "o"
case [1..2, 3..4]
in [_, *, r]
  p r
end
o = 0
case [Pt.new(1), Pt.new(2)]
in [*, o]
  p o
end
puts o, o == 0

# a mix: the element is of the class the local held, or of another
m = "o"
case [1, "s"]
in [*, m]
  p m
end
p m == "s"
i = 0
case [1, "s"]
in [*, i]
  p i
end
puts "#{i} is #{i.class}"

# what a Struct and an object deconstruct to
Pair = Struct.new(:l, :r)
class Row
  def initialize(*v) = (@v = v)
  def deconstruct = @v
end
s = 0
case Pair.new(:q, "z")
in [*, s]
  p s
end
w = :o
case Row.new(1, "z", 2.5)
in Row[*, w, _]
  p w
end
p s, w

# in a method that takes Arrays of two kinds; a comparison is its answer
def last_of(row)
  x = "none"
  case row
  in [_, *, x]
    puts "matched"
  else
    puts "too short"
  end
  puts "#{x} is #{x.class}"
  x == :r
end
p last_of([:q, :r]), last_of([1, 2.5]), last_of(["a"])

# two arms, in a loop; no match leaves the earlier value
rows = [[:a, :b], [1, "s", 2.5], [nil]]
v = "o"
k = 0
while k < 3
  case rows[k]
  in [_, v]
    p v
  in [_, *, v]
    p v
  else
    p :no
  end
  k += 1
end
p v

# `in` and `=>` as expressions
e = "o"
g = ([:q, :r] in [*, e])
p g, e
j = 0
[1, :q] => [*, j]
p j

# The local is typed by the pattern only where every other use of it prints
# or compares it. Each of these does more with it, and keeps the type it
# had: the element here is a String, as the local is.
class Box
  attr_reader :v
  def initialize(v) = (@v = v)
end
b1 = "o".dup
case [1, "s".dup]
in [*, b1] then puts "hit"
end
held = [b1]
held[0] << "y"
p b1
b2 = "o".dup
case [1, "s".dup]
in [*, b2] then puts "hit"
end
box = Box.new(b2)
box.v << "m"
p b2
b3 = "o"
case [1, "s"]
in [*, b3] then puts "hit"
end
p b3.upto("u").to_a
b4 = "o"
case [1, "s"]
in [*, b4] then puts "hit"
end
p b4.equal?(b4), !b4
