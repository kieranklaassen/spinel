# A String parameter of a `tap`, `then` or `yield_self` block that a proc
# literal written in the block changes by position: what the block sees of
# it. (What the receiver keeps afterwards is not asked here.)
u1 = "qrs".dup
u1.tap { |q| f = -> { q[0, 2] = "Z" }; f.call; p q }
u2 = "qrs".dup
u2.then { |q| f = -> { q.insert(1, "-") }; f.call; p q }
u3 = "qrs".dup
u3.yield_self { |q| f = proc { q.setbyte(0, 65) }; f.call; p q }
u4 = "qrs".dup
u4.tap { |q| f = -> { q.slice!(0) }; f.call; p q }
u5 = "qrs".dup
u5.tap { |q| f = -> { q.clear; 1 }; f.call; p q }

# the same over a method's parameter, and a closure kept past the block
def change(x) = x.tap { |q| f = -> { q.insert(0, "+") }; f.call; p q }
change("qrs".dup)
kept = nil
u6 = "qrs".dup
u6.tap { |q| kept = -> { q.insert(1, "-"); q } }
p kept.call

# an Array and a Hash changed the same way are the receiver itself
a = [1, 2, 3]
a.tap { |q| f = -> { q.insert(1, 7); q[0] = 9 }; f.call }
p a
h = { 1 => 2 }
h.tap { |q| f = -> { q[3] = 4 }; f.call }
p h[3], h.size
