# A rest Array the call makes whole in its argument list (an empty rest, a
# lone splat) is held by nothing but the callee. A method with a captured
# local allocates that local's cell before its body runs, so the rest has
# to be rooted ahead of the first cell.

class K
  # the rest itself is captured
  def hold(n, *args, &block) = lambda { args << n }
  # another parameter is captured, the rest comes after it
  def tail(n, *rest)
    f = lambda { n + 1 }
    [f.call, rest]
  end
  def self.pair(n, *a) = proc { [n, a] }
end

def top(n, *a) = -> { [n, a] }
def with_key(n, *a, k: 3) = -> { [n, a, k] }
def with_post(n, *a, z) = -> { [n, a, z] }
def rescued(n, *args)
  f = lambda { n + 1 }
  raise "odd" if n == 1
  [f.call, args]
rescue StandardError
  [0, args]
end

k = K.new

rs = []
3.times { |i| f = k.hold(i); f.call; rs << f.call }
p rs

rs = []
3.times { |i| rs << k.tail(i) }
p rs

ints = [7, 8]
strs = ["a", "b"]
flts = [1.5, 2.5]
rs = []
3.times { |i| rs << top(i, *ints).call }
3.times { |i| rs << top(i, *strs).call }
3.times { |i| rs << top(i, *flts).call }
p rs

rs = []
3.times { |i| rs << K.pair(i).call }
3.times { |i| rs << K.pair(i, *strs).call }
p rs

rs = []
3.times { |i| rs << with_key(i).call }
3.times { |i| rs << with_key(i, k: 4).call }
3.times { |i| rs << with_post(i, :z).call }
p rs

rs = []
3.times { |i| rs << rescued(i) }
p rs

rs = []
3.times { |i| rs << send(:top, i).call }
3.times { |i| rs << k.public_send(:tail, i) }
3.times { |i| rs << method(:top).call(i).call }
p rs

# held already: a rest of two plain arguments, and no rest parameter
rs = []
3.times { |i| rs << top(i, i + 1, i + 2).call }
p rs
