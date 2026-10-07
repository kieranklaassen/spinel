# A call answered without its receiver still runs the receiver. Integer#size
# is the word size and a Float Range covers no non-number, whatever the
# receiver holds; respond_to? with a literal name, and is_a? against a class
# the receiver's type rules out, are answered at compile time. The receiver's
# own effects happen all the same, once, where the call stands.
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
p int.size == 0.size
int.size
p int.size + int.size == 2 * 0.size
p $n
p frange.cover?("a"), frange.include?(:a), frange.member?(nil)
p frange === "a", frange.eql?("a")
p $n

# the receiver can raise
z = 0
begin
  p((7 / z).size)
rescue ZeroDivisionError => e
  puts e.message
end

# respond_to? with a literal name
p int.respond_to?(:size), str.respond_to?(:zork), int.respond_to?("abs")
p shape.respond_to?(:zork), shape.respond_to?(:area)
int.respond_to?(:size)
p $n
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

# in order with its neighbours
p [($n += 10), (int.respond_to?(:size) ? $n : 0), ($n += 100)]

# and not where Ruby does not reach it
w = false && int.respond_to?(:size)
w = false && (int.is_a?(Shape) ? 1 : 2)
p w
p $n
