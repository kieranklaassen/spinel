# A block written at a `super` is the block the parent yields to, also in a
# method that was itself called with `&proc`. The proc is that method's own
# block: its own `yield` and `b.call` reach it, the parent's yields do not.
# The parent's yields called the proc, and the written block never ran.
class Two
  def go
    r = []
    r << (yield 1)
    r << (yield 2)
    r
  end

  def self.make
    r = []
    r << (yield 3)
    r << (yield 4)
    r
  end
end

class Scaled
  def go(k)
    r = []
    r << (yield k)
    r << (yield k + 1)
    r
  end
end

# the super's value, then the method's own yield
class Tens < Two
  def go
    a = super() { |x| x * 10 }
    yield a
  end

  def self.make
    a = super() { |x| x * 10 }
    yield a
  end
end

# a bare `super` with a block; the block reads a parameter and a local
class Times < Scaled
  def go(k)
    m = k + 1
    a = super { |x| x * k + m }
    yield a
  end
end

# the method names its block and calls it
class Named < Two
  def go(&b)
    a = super() { |x| x * 10 }
    b.call(a)
  end
end

# the super as a statement: its block fills a local
class Filled < Two
  def go
    out = []
    super() { |x| out << x * 10 }
    yield out
  end
end

# the super inside an iterator's block
class Looped < Two
  def go
    out = []
    [1, 2].each { |q| super() { |x| out << x * 10 }; out << q * 100 }
    yield out
  end
end

# the written block calls the method's own block
class Chained < Two
  def go(&b)
    a = super() { |x| b.call(x + 1) }
    b.call(a)
  end
end

# three classes, a written block at each super
class Mid < Two
  def go
    t = super() { |y| y + 100 }
    t << (yield 3)
    t
  end
end

class Low < Mid
  def go
    a = super() { |x| x * 10 }
    yield a
  end
end

# nothing behind the `&`
class Guarded < Two
  def go
    a = super() { |x| x * 10 }
    block_given? ? (yield a) : a
  end
end

# the parent yields from a block of its own
class Via < Two
  def pair
    r = []
    r << (yield 1)
    r << (yield 2)
    r
  end

  def go
    pair { |q| yield q }
  end
end

class OverVia < Via
  def go
    a = super() { |x| x * 10 }
    yield a
  end
end

# the parent hands its block on, then yields; the written block yields too
module Pairs
  def pair
    r = []
    r << (yield 1)
    r << (yield 2)
    r
  end

  def go(&b)
    r = pair(&b)
    r << (yield 3)
    r
  end
end

class OverPairs
  include Pairs

  def go
    a = super() { |x| yield x + 1 }
    yield a
  end
end

# already so: the parent takes its block as a parameter
class Taker
  def go(&b)
    [b.call(1), b.call(2)]
  end
end

class OverTaker < Taker
  def go
    a = super() { |x| x * 10 }
    yield a
  end
end

# already so: the proc itself handed on to the parent
class Handed < Two
  def go(&b)
    a = super(&b)
    b.call(a)
  end
end

tag = proc { |v| [:got, v] }
la = ->(v) { [:lambda, v] }
none = nil

p Tens.new.go(&tag)
p Tens.make(&tag)
p Times.new.go(3, &tag)
p Named.new.go(&tag)
p Filled.new.go(&tag)
p Looped.new.go(&tag)
p Chained.new.go(&tag)
p Low.new.go(&tag)
p Mid.new.go(&tag)
p OverVia.new.go(&tag)
p OverPairs.new.go(&tag)
p Tens.new.go(&la)
p Tens.new.go(&:inspect)

# a proc, a literal block, the proc again
p Filled.new.go(&la)
p(Filled.new.go { |v| v.size })
p Filled.new.go(&la)

p OverTaker.new.go(&tag)
p Handed.new.go(&tag)
p Guarded.new.go(&none)
