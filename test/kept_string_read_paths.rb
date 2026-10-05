# A String a method keeps and its caller mutates in place afterwards is
# refused only where the kept String is read back through what holds it
# (test/reject/kept_string_*.rb). Each program here is right and compiles.
class Box
  attr_accessor :s, :n
end
class Line
  attr_reader :text
  def initialize(text)
    @text = text
  end
  def show
    puts "> " + @text
  end
end
Pair = Struct.new(:x, :y)

# the object that kept the String is gone before the mutation
buf = +"alpha"
Line.new(buf).show
buf << ", beta"
Line.new(buf).show

# handed over again before each read
st = Box.new
st.s = buf
puts st.s
buf << ", gamma"
st.s = buf
puts st.s

# kept, mutated, never read back
k = Box.new
t = +"t"
k.s = t
t << "u"
puts t

# read before the mutation only
r = Box.new
u = +"u"
r.s = u
puts r.s
u << "v"
puts u

# mutated before it is handed over
w = +"w"
w << "x"
h = Box.new
h.s = w
puts h.s

# the variable names another String by the time it is mutated
y = +"y"
g = Box.new
g.s = y
y = +"z"
y << "!"
puts g.s

# the hand-over in one arm, the mutation in the other
c = +"c"
f = Box.new
if ARGV.empty?
  f.s = c
else
  c << "d"
end
puts f.s

# a byte written in place is seen by both
q = +"hello"
e = Box.new
e.s = q
q.setbyte(0, 74)
puts e.s

# a frozen String raises on the mutation
z = (+"frozen").freeze
d = Box.new
d.s = z
begin
  z << "!"
rescue FrozenError
  puts "FrozenError"
end
puts d.s

# a Struct kept only for the call
def first_of(pair) = pair.x
m = +"m"
puts first_of(Pair.new(m, 1))
m << "n"
puts first_of(Pair.new(m, 2))

# in a loop the variable names another String by the time it is mutated
def rounds
  s = +"s"
  b = Box.new
  b.s = s
  i = 0
  while i < 3
    s << "x" if i > 0
    puts b.s
    s = +"n"
    i += 1
  end
end
rounds

# a block that runs later mutates after the read
def later
  s = +"l"
  b = Box.new
  b.s = s
  h = Hash.new { |hh, k| s << "x"; 1 }
  puts b.s
  puts h[:a]
  puts s
end
later
