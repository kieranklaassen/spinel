# zip or combination with a block, inside a method that yields. Such a method
# is spliced into its caller with its locals renamed, and both arms asked for
# the block's parameters by the new name: a zip left them nil, and a
# combination did not build.
def each_pair_of(a, b)
  a.zip(b) { |x, y| yield x, y }
end
each_pair_of([1, 2], ["a", "b"]) { |n, s| p [n, s] }

# the yield after the loop
def sums(a, b)
  r = []
  a.zip(b) { |x, y| r << x + y }
  yield r
end
sums([1, 2], [10, 20]) { |r| p r }

# a block handed on as &blk
def call_each(a, b, &blk)
  a.zip(b) { |x, y| blk.call(x, y) }
end
call_each([1.5, 2.5], [3, 4]) { |x, y| p x * y }

# one parameter takes the pair
def rows(a, b)
  a.zip(b) { |pr| yield pr }
end
rows(["a", "b"], ["c", "d"]) { |pr| p pr }

# a local of the method under a parameter's name is itself again afterwards
def shadow(a, b)
  x = :kept
  a.zip(b) { |x, y| yield x + y }
  yield x
end
shadow([1, 2], [3, 4]) { |v| p v }

# a zip inside an each
def grid(a, b)
  a.each { |q| a.zip(b) { |x, y| yield q * 100 + x * 10 + y } }
end
grid([1, 2], [3, 4]) { |v| p v }

# called twice with other element kinds
each_pair_of(["k"], [2.5]) { |n, s| p [n, s] }

def pairs(a)
  a.combination(2) { |x, y| yield x + y }
end
pairs([3, 4, 5]) { |s| p s }

def spans(a)
  a.combination(2) { |x, y| yield y - x }
end
spans([1.5, 2.5, 4.0]) { |d| p d }

def orders(a)
  a.permutation(2) { |pr| yield pr }
end
orders([1, 2, 3]) { |pr| p pr }

class Table
  def initialize(names, ages) = (@names = names; @ages = ages)

  def each
    @names.zip(@ages) { |n, a| yield n, a }
  end
end
Table.new(["ann", "bob"], [31, 27]).each { |n, a| puts "#{n} #{a}" }
