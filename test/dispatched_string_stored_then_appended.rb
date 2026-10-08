# A String a method builds, called on an element whose class is found at
# run time, is stored in an Array or a Hash and changed in place there.
class K
  def initialize(x) = @x = x
  def plus = @x + "a"
  def join(y) = @x + y
  def text = "#{@x}-k"
  def held = @x
end
class L < K
  def plus = @x + "b"
  def text = @x.upcase
end
# a class nothing makes: its `plus` is not typed, and the call's answer is
# boxed
class Q
  def initialize(x) = @x = x
  def plus = @x + "a"
  def join(y) = @x + y
  def text = @x
end
b = [K.new("p".dup), L.new("q".dup)]

z = [b[0].plus, b[1].plus]
z.each { |e| e << "!" }
p z
z[0] << "?"
p z

h = { a: b[0].plus, c: b[1].plus }
h[:a] << "!"
h[:c].upcase!
p h[:a], h[:c]

w = []
w << b[0].text
w << b[1].text
w[0].concat("+")
w[1] << "+"
p w

# with an argument
j = [b[0].join("x"), b[1].join("y")]
j.each { |e| e << "!" }
p j

# each call builds a String of its own
p b[0].plus, b[1].plus

# one class answers an Integer
class M
  def plus = 1
end
m = [K.new("r".dup), M.new]
y = [m[0].plus, m[1].plus]
y[0] << "!"
p y

# one answers nil
class N
  def plus = nil
end
n = [K.new("s".dup), N.new]
v = [n[0].plus, n[1].plus]
v.each { |e| e << "!" if e }
p v

# a method that answers the String it holds is left as it was
g = [b[0].held, b[1].held]
p g
