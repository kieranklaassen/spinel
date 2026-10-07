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
