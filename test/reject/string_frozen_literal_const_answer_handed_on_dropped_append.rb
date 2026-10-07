# The same with the answer of a blocked `each`, which is its receiver,
# handed to a method that stores.
class Bag
  def initialize(v); @v = v; end
  def add; @v << +"s"; end
end
W = ["q"]
Bag.new(W.each { |s| s }).add
W.find { |s| s == "s" } << "!"
p W
