# A local written in a method of a prepended module. The method is copied
# in front of the class after the pass that gives every method's locals
# their slots, and the copy's own locals were given none: the C read and
# wrote a variable it never declared, and did not build.
module Doubled
  def total(a)
    twice = a * 2
    twice + super(a)
  end
end

# the class's own method beneath the module's
class Plain
  prepend Doubled
  def total(a)
    a + 100
  end
end
p Plain.new.total(3)

# the superclass's method beneath it
class Base
  def total(a)
    a + 200
  end
end
class Below < Base
  prepend Doubled
end
p Below.new.total(3)

# the module in front of a class and of its subclass
class Under < Plain
  prepend Doubled
end
p Under.new.total(3)

# a local that takes super's value
module Wrapped
  def pair
    v = super
    [v, :w]
  end

  def sized(a)
    v = super(a)
    v.length
  end
end

class Pair
  prepend Wrapped
  def pair
    [3, 6]
  end

  def sized(a)
    "x" * a
  end
end
p Pair.new.pair
p Pair.new.sized(4)

# a method with nothing beneath it: a counter, a compound write, two
# targets at once, a rescue's binding, a block that writes a local
module Counted
  def count(n)
    i = 0
    sum = 0
    while i < n
      sum += i
      i += 1
    end
    sum
  end

  def both(a)
    x, y = a, a + 1
    x * y
  end

  def safe(n)
    begin
      raise ArgumentError, "negative" if n < 0
      r = n.to_s
    rescue => e
      r = e.message
    end
    r
  end

  def gather(a)
    t = 0
    [a, 2].each { |q| t += q }
    t
  end
end

class Counter
  prepend Counted
end
c = Counter.new
p c.count(5)
p c.both(3)
p c.safe(7)
p c.safe(-1)
p c.gather(5)
