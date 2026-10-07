# A Method made where it is handed over as a block (&o.method(:val)) reaches
# the block slot boxed, and nothing else holds it while its Proc is made.

class K
  def initialize(n) = @n = n
  def val = @n
  def twice(x) = x * 2 + @n
  def me = self
end

def top0 = 40
def top1(x) = x + 1
def y0 = yield
def y1(a) = yield(a)
def kept(&blk) = blk
def pick(i) = i >= 0 ? K.new(i).method(:val) : nil

def go
  rs = []
  3.times { |i| rs << y0(&K.new(i).method(:val)) }
  3.times { |i| rs << y1(i, &K.new(i).method(:twice)) }
  rs
end

rs = []
3.times { |i| rs << y0(&method(:top0)) }
3.times { |i| rs << y1(i, &method(:top1)) }
p rs

rs = []
3.times { |i| rs << y0(&K.new(i).method(:val)) }
3.times { |i| rs << y1(i, &K.new(i).method(:twice)) }
p rs

rs = []
3.times { |i| o = K.new(i); rs << y0(&o.method(:val)) }
3.times { |i| o = K.new(i); rs << y1(i, &o.method(:twice)) }
3.times { |i| rs << y0(&K.new(i).me.method(:val)) }
p rs

# after another block in the same statement
rs = []
3.times { |i| rs << 2.times.map { 0 }.size + y0(&K.new(i).method(:val)) }
p rs

p go

# out of a call that can also answer nil: yielded to, and kept as a block
rs = []
3.times { |i| rs << y0(&pick(i)) }
3.times { |i| rs << kept(&pick(i)).call }
p rs

# held already: a Method in a local, and Method#to_proc
rs = []
3.times { |i| m = K.new(i).method(:val); rs << y0(&m) }
3.times { |i| rs << K.new(i).method(:twice).to_proc.call(i) }
p rs
