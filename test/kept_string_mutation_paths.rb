# A String variable handed to a method that keeps it is refused only when it
# is mutated in place afterwards through the variable. Every path here keeps
# compiling: the String is finished before it is handed over, the variable
# names another String by the time it is mutated, the two never run on one
# path, or the String is mutated through what holds it.
class Box
  attr_accessor :s
  def initialize; @q = []; end
  def add(v); @q << v; end
  def q = @q
end
class Held
  def initialize(s); @s = s; end
  def s = @s
end
class Named
  def initialize(name:); @name = name; end
  def name = @name
end
def wrap(v) = [v]

# built, then handed over
b = Box.new
s = +"a"
s << "b"
b.s = s
puts b.s

# mutated through its holder
m = +"m"
h = Held.new(m)
h.s << "n"
puts h.s, m

# rebound before the mutation
t = +"t"
b.add(t)
t += "u"
t << "v"
puts b.q[0], t

# a fresh String each round
3.times do |i|
  r = +"r"
  r << i.to_s
  b.add(r)
end
puts b.q.join(",")

# the hand-over and the mutation in different arms
u = +"u"
if ARGV.empty?
  b.s = u
else
  u << "x"
end
puts b.s

# a return between them
def build(b, early)
  w = +"w"
  if early
    b.s = w
    return w
  end
  w << "x"
  w
end
puts build(b, true), b.s, build(b, false)

# a returned Array nobody keeps
x = +"x"
wrap(x)
x << "y"
puts x

# handed over by keyword: shared
k = +"k"
n = Named.new(name: k)
k << "l"
puts n.name

# a frozen literal raises, as in CRuby
f = "f"
b.s = f
begin
  f << "g"
rescue FrozenError
  puts "frozen"
end
puts b.s

# a block that runs once
y = +"y"
1.tap do
  y << "z"
  b.s = y
end
puts b.s
