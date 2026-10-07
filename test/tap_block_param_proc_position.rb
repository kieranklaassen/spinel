# A String parameter of a `tap`, `then` or `yield_self` block that a proc
# literal written in the block changes by position is the receiver: the
# block sees the change, and so does the receiver afterwards.
u0 = "qrs".dup
u0.tap { |q| f = -> { q[0] = "Z" }; f.call; p q }
p u0
u1 = "qrs".dup
u1.tap { |q| f = -> { q[0, 2] = "Z" }; f.call; p q }
p u1
u2 = "qrs".dup
u2.then { |q| f = -> { q.insert(1, "-") }; f.call; p q }
p u2
u3 = "qrs".dup
u3.yield_self { |q| f = proc { q.setbyte(0, 65) }; f.call; p q }
p u3
u4 = "qrs".dup
u4.tap { |q| f = -> { q.slice!(0) }; f.call; p q }
p u4
u5 = "qrs".dup
u5.tap { |q| f = -> { q.clear; 1 }; f.call; p q }
p u5

# the same over a method's parameter, and a closure kept past the block
def change(x) = x.tap { |q| f = -> { q.insert(0, "+") }; f.call; p q }
u6 = "qrs".dup
change(u6)
p u6
kept = nil
u7 = "qrs".dup
u7.tap { |q| kept = -> { q.insert(1, "-"); q } }
p kept.call
p u7

# an Array and a Hash changed the same way are the receiver itself
a = [1, 2, 3]
a.tap { |q| f = -> { q.insert(1, 7); q[0] = 9 }; f.call }
p a
h = { 1 => 2 }
h.tap { |q| f = -> { q[3] = 4 }; f.call }
p h[3], h.size
