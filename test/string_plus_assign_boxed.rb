# `s += v` is `s = s + v`. With `v` in a box, String#+ takes a String or what
# answers to_str and raises TypeError for anything else, an Integer included.
def pick(i) = i > 0 ? 1 : "x"
v = pick(1)

s = "q".dup
begin
  s += v
rescue TypeError => e
  puts e.message
end
p s

a = ["q"]
begin
  a[0] += v
rescue TypeError => e
  puts e.message
end
p a

def add(s, x)
  s += x
  s
end
begin
  p add("q", v)
rescue TypeError => e
  puts e.message
end

# an object that answers to_str is added as that String
class Path
  def initialize(s) = @s = s
  def to_str = @s
end
def part(i) = i > 0 ? Path.new("/tmp") : "/"
t = "cd ".dup
t += part(1)
p t
b = ["cd "]
b[0] += part(1)
p b

# a Symbol and nil
def sym(i) = i > 0 ? :name : "x"
k = "k=".dup
begin
  k += sym(1)
rescue TypeError => e
  puts e.message
end
p k
[nil, 1.5].each do |x|
  n = "n=".dup
  begin
    n += x
  rescue TypeError => e
    puts e.message
  end
  p n
end

# an attribute, a Struct member and a receiver in a box, each as a statement:
# the value is an element of a mixed Array
class Tag
  attr_accessor :s
  def initialize = @s = "q".dup
end
Row = Struct.new(:s)
def tag_or_row(i) = i > 0 ? Tag.new : Row.new("q".dup)
mix = [1, "b"]
one = mix[0]
tag = Tag.new
begin
  tag.s += one
  puts "no raise"
rescue TypeError => e
  puts e.message
end
tag.s += mix[1]
p tag.s
row = Row.new("q".dup)
begin
  row.s += one
  puts "no raise"
rescue TypeError => e
  puts e.message
end
row.s += mix[1]
p row.s
any = tag_or_row(1)
begin
  any.s += one
  puts "no raise"
rescue TypeError => e
  puts e.message
end
any.s += mix[1]
p any.s

# as before: a boxed String, the spelled-out form, an instance variable
u = "q".dup
u += pick(0)
p u
w = "q".dup
begin
  w = w + v
rescue TypeError => e
  puts e.message
end
p w
class Box
  def initialize = @s = "q".dup
  def add(x)
    @s += x
  rescue TypeError => e
    puts e.message
  end
  def text = @s
end
x = Box.new
x.add(v)
p x.text
