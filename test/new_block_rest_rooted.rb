# A block or gathered rest given to new outlives the object's allocation
class Keep
  def initialize(&blk)
    @blk = blk
  end

  def call(x) = @blk.call(x)
end

class Bag
  attr_reader :items

  def initialize(*items)
    @items = items
  end
end

class Tagged < StandardError
  attr_reader :tags

  def initialize(*tags)
    super("tagged")
    @tags = tags
  end
end

class Ran
  attr_reader :v, :rest

  def initialize(*rest)
    @rest = rest
    @v = yield(1)
  end
end

class Once
  attr_reader :v

  def initialize
    @v = yield(1)
  end
end

class Opts
  attr_reader :kw

  def initialize(a, **kw)
    @a = a
    @kw = kw
  end
end

class Plain
  attr_reader :kw

  def initialize(a)
    @a = a
    @kw = {}
  end
end

class Adder
  def initialize(n) = @n = n
  def add(x) = x + @n
end

N = 20_000

# the proc of a block literal
keeps = []
N.times { |i| keeps << Keep.new { |x| x + i } }
wrong = 0
keeps.each_with_index { |k, i| wrong += 1 unless k.call(1) == i + 1 }
p wrong

# the proc a Method is turned into
keeps = []
N.times { |i| keeps << Keep.new(&Adder.new(i).method(:add)) }
wrong = 0
keeps.each_with_index { |k, i| wrong += 1 unless k.call(1) == i + 1 }
p wrong

# the array an empty rest gathers
bags = []
N.times { |i| b = Bag.new; b.items << i; bags << b }
wrong = 0
bags.each_with_index { |b, i| wrong += 1 unless b.items == [i] }
p wrong

# the array a splat is copied into
src = [1, 2]
bags = []
N.times { |i| b = Bag.new(*src); b.items << i; bags << b }
wrong = 0
bags.each_with_index { |b, i| wrong += 1 unless b.items == [1, 2, i] }
p wrong

# an exception class allocates through another call
errs = []
N.times { |i| e = Tagged.new; e.tags << i; errs << e }
wrong = 0
errs.each_with_index { |e, i| wrong += 1 unless e.tags == [i] }
p wrong

# an initialize that yields: the array its rest gathers
double = proc { |x| x * 2 }
rans = []
N.times { |i| r = Ran.new(&double); r.rest << i; rans << r }
wrong = 0
rans.each_with_index { |r, i| wrong += 1 unless r.rest == [i] && r.v == 2 }
p wrong

# and the proc made at the call for it to yield to
onces = []
N.times { |i| onces << Once.new(&Adder.new(i).method(:add)) }
wrong = 0
onces.each_with_index { |o, i| wrong += 1 unless o.v == i + 1 }
p wrong

# the hash a keyword rest gathers, through a class held in a variable
kinds = [Plain, Opts]
opts = []
N.times { |i| o = kinds[1].new(i); o.kw[:id] = i; opts << o }
wrong = 0
opts.each_with_index { |o, i| wrong += 1 unless o.kw == { id: i } }
p wrong
