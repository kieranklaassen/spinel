# A writer on a boxed receiver given a value of nil type that is no nil
# literal (a method that answers nil, `(bump; nil)`): the value runs before
# nil is stored, as it does on a typed receiver. The store used to take nil
# and never run it.
class Node
  attr_accessor :name, :parent
  def initialize(n) = @name = n
end
Pair = Struct.new(:left)

$calls = 0
def detach(nd)
  puts "detach #{nd.name}"
  nil
end

def bump
  $calls += 1
  nil
end

items = [Node.new("a"), Node.new("b")]
items.each { |nd| nd.parent = detach(nd) }
items.each { |nd| p(nd.parent = bump) }
items.each { |nd| nd.send(:parent=, (bump; nil)) }
for nd in items
  nd.parent = (bump if $calls < 99)
end
p $calls

x = [Node.new("m"), 1][0]
x.parent = begin; bump; nil; end
x.parent = puts("stored")
x.parent = nil
p $calls, x.parent

pairs = [Pair.new(1), Pair.new(2)]
p pairs.map { |q| q.left = bump }
p pairs.map { |q| q.left }
p $calls

# A receiver nothing else holds stays alive while the value runs: the value
# allocates, and the store comes after it.
def churn
  a = []
  40.times { |i| a << ("s" + i.to_s) * 3 }
  nil
end
def mk(n) = [Node.new(n), 1][0]
keep = []
mk("a").parent = churn
keep << "k1" * 5
30.times { |i| mk("l").parent = churn; keep << "k2" if i == 29 }
mk("s")&.parent = churn
keep << "k3" * 2
p keep

# A value this place has no expression for keeps the plain nil, and the
# program still builds: a rescue modifier over a call that answers nil, an
# instance-variable write, a yield whose block ends in a boxed writer.
def quiet = nil
def take(v) = nil
def outer(nd)
  nd.parent = take(yield)
  nil
end
w = [Node.new("w"), 1][0]
x.parent = (quiet rescue nil)
x.parent = @z = nil
outer(x) { w.name = "w" }
p x.parent, w.name
# Under `&.` the value of a receiver that is there runs.
x&.parent = bump
p $calls
# What the value hoists runs with it, after the receiver.
def named(n)
  puts "named #{n}"
  [Node.new(n), 1][0]
end
named("o").parent = take(detach(x))
p(named("q").parent = take(detach(x)))
