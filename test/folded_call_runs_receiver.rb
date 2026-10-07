# A call answered without its receiver still runs the receiver. Integer#size
# is the word size and a Float Range covers no non-number, whatever the
# receiver holds; respond_to? with a literal name, and is_a? against a class
# the receiver's type rules out, are answered at compile time. Where the call
# is the first thing its statement runs, the receiver's own effects happen
# all the same, once.
class Shape
  def area; 1; end
end
class Other; end

$n = 0
def int;    $n += 1; 7; end
def str;    $n += 1; "ab"; end
def frange; $n += 1; (1.0..2.0); end
def shape;  $n += 1; Shape.new; end

# a builtin that needs no receiver
int.size
x = int.size
p int.size > 0
p int.size + 1 > 1
p x > 0, $n
p frange.cover?("a")
p frange.include?(:a)
y = frange.member?(nil)
p frange === "a"
p frange.eql?("a")
p y, $n

# the receiver can raise
z = 0
begin
  p((7 / z).size)
rescue ZeroDivisionError => e
  puts e.message
end

# respond_to? with a literal name
p int.respond_to?(:size)
p str.respond_to?(:zork)
p int.respond_to?("abs")
p shape.respond_to?(:zork)
r = shape.respond_to?(:area)
int.respond_to?(:size)
p r, $n
x = 0
p((x = 5).respond_to?(:size))
p x
a = [1, 2, 3]
p a.pop.respond_to?(:zork)
p a

# deciding an if, an unless and a ternary
if int.respond_to?(:size)
  puts "responds"
else
  puts "does not"
end
puts "no zork" unless str.respond_to?(:zork)
puts(int.respond_to?(:zork) ? "zork" : "no zork")
p $n
if int.is_a?(Shape)
  puts "a shape"
else
  puts "not a shape"
end
puts(shape.is_a?(Other) ? "other" : "not other")
puts "not exactly a shape" unless str.instance_of?(Shape)
v = if int.kind_of?(Other)
  puts "then"
  1
else
  puts "else"
  2
end
p v
p $n

# in a method, a block and the arm of an if
def kind = int.is_a?(String) ? "s" : "i"
p kind
[1, 2].each { |e| p int.respond_to?(:abs) if e > 1 }
if z == 0
  w = int.size
  p w > 0
end
p $n

# and not where Ruby does not reach it
w = false && int.respond_to?(:size)
w = false && (int.is_a?(Shape) ? 1 : 2)
p w
p $n
