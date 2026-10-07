# The defaults a call fills run in the order of the parameters, where the
# call stands, whatever order the C compiler runs a call's arguments in.
$n = 0
def bump = ($n += 100)
def note(a) = (puts "note #{a}"; a)

def two(x = ($n += 1), y = ($n += 1)) = [x, y]
def three(x = ($n += 1), y = ($n += 1), z = ($n += 1)) = [x, y, z]
def lit_between(x = ($n += 1), y = 5, z = ($n += 1)) = [x, y, z]
def then_string(x = ($n += 1), y = "s#{$n += 1}") = [x, y]
def string_then(x = "s#{$n += 1}", y = ($n += 1)) = [x, y]
def between(w = "a#{$n += 1}", x = ($n += 1), y = "b#{$n += 1}", z = ($n += 1)) = [w, x, y, z]
def reads_first(x = $n, y = ($n += 1)) = [x, y]
def reads_last(x = ($n += 1), y = $n) = [x, y]
def floats(x = ($n += 1).to_f, y = ($n += 1) * 1.5) = [x, y]
def noted(x = note(:x), y = note(:y)) = [x, y]
def keys(x: ($n += 1), y: ($n += 1)) = [x, y]
def pos_key(a = ($n += 1), k: ($n += 1)) = [a, k]
def after(a, x = ($n += 1), y = ($n += 1)) = [a, x, y]

class Point
  attr_reader :v
  def initialize(v); @v = v; end
end
def then_object(x = ($n += 1), y = Point.new($n += 1)) = [x, y.v]

class Pair
  def initialize(x = ($n += 1), y = ($n += 1)); @x = x; @y = y; end
  def to_a = [@x, @y]
  def self.make(x = ($n += 1), y = "s#{$n += 1}") = [x, y]
end
module Tool
  def self.pair(x = ($n += 1), y = ($n += 1)) = [x, y]
end

p two
p two(10)
p three
p three(10)
p lit_between
p then_string
p string_then
p between
p reads_first
p reads_last
p floats
p noted
p keys
p keys(y: 9)
p pos_key
p pos_key(k: 9)
p after(7)
p after($n += 1)
p then_object
p Pair.new.to_a
p Pair.new(5).to_a
p Pair.make
p Tool.pair

# in the call's place: after what stands before it in the expression
p "#{bump} #{two}"
p [bump, then_string]
v = two
p v
def in_method = two
p in_method
p([1, 2].map { |_| three })
i = 0
while i < 2
  p then_string
  i += 1
end
p $n
