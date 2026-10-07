# A hand-written writer given a value of nil type that is no nil literal: a
# method that answers nil, `(bump; nil)`, `(bump if c)`. The value runs once
# and the assignment answers nil. The temporary the call bound the value to
# was declared void, and the generated C did not build.
class Node
  def initialize(n) = @name = n
  def parent=(x)
    @parent = x
  end
  def parent = @parent
  def name = @name
end
$c = 0
def bump
  $c += 1
  nil
end
def detach(nd)
  puts "detach #{nd.name}"
  nil
end

a = Node.new("a")
a.parent = detach(a)
p a.parent
y = (a.parent = bump)
p y
p(a.parent = (bump; nil))
r = [Node.new("b"), Node.new("c")].map { |nd| nd.parent = detach(nd) }
p r
i = 0
while i < 2
  a.parent = (bump if i < 9)
  i += 1
end
p $c

# a value of another type is stored as before
a.parent = (bump; "stored")
p a.parent
p $c

# a writer assignment inside the value answers its own right-hand side: a
# block's last one, run where the method yields, and a chained one
class Flag
  def on=(v)
    @on = v
    :set
  end
  def on = @on
end
def note(x)
  puts "note #{x.inspect}"
  nil
end
def mark(f)
  f.on = note(yield)
end
f = Flag.new
g = Flag.new
mark(f) { g.on = 6 }
p f.on, g.on
f.on = g.on = bump
p f.on, g.on, $c
