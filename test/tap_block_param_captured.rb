# The parameter of a `tap` or `then` block, read or changed inside a closure
# written in that block: a block handed to a method the program defines with
# `yield`, or a lambda. The closure captures the parameter, and the receiver
# has to see what was done through it.

class Bag
  def initialize(a) = @a = a
  def each
    @a.each { |v| yield v }
  end
end

bag = Bag.new([1, 2])

# an Array built through the parameter, inside the program's own each
x = [].tap { |acc| bag.each { |v| acc << v } }
p x

# a String appended to the same way
s = "q".dup
s.tap { |b| bag.each { |v| b << v.to_s } }
p s

# two levels: a builtin each around the program's own
y = [].tap { |acc| [1, 2].each { |i| bag.each { |v| acc << i * v } } }
p y

# a Hash filled through the parameter
h = {}.tap { |m| bag.each { |v| m[v] = v * 10 } }
p h[1], h[2], h.size

# a lambda that captures the parameter and is called in the block
w = "k".dup
w.tap { |b| add = ->(v) { b << v }; add.call("7"); add.call("8") }
p w

# then: the block's answer, computed through a captured parameter
n = [3, 4].then { |a| t = 0; bag.each { |v| t += a[v - 1] * v }; t }
p n

# the value of the tap is the receiver itself
k = [5]
r = k.tap { |acc| bag.each { |v| acc << v } }
p r.equal?(k), k

# a method's tail
def collect(bag) = [].tap { |acc| bag.each { |v| acc << v + 100 } }
p collect(bag)

# an Integer receiver: the parameter is read in the closure
t = 0
5.tap { |q| bag.each { |v| t += q * v } }
p t
