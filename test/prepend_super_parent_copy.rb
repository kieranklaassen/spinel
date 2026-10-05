# A `super` with a block, in the own method of a class that has a prepend,
# reaches the parent's method. Where the parent has a prepend too, that is
# the copy the parent's prepend put in front of the parent's own body. The
# own body is kept under one name in each class, and the splice of a
# yielding parent asked the parent's chain for that name: it took the
# parent's own body and went past the prepended copy. Below, `Child#go`
# answered [2, 3] for [10, 20].
module Tens
  def go
    super() { |x| x * 10 }
  end
end

class Parent
  prepend Tens
  def go
    r = []
    r << (yield 1)
    r << (yield 2)
    r
  end
end

class Child < Parent
  prepend Tens
  def go
    super() { |x| x + 1 }
  end
end
p Parent.new.go
p Child.new.go

# a third class down, and a class with no prepend between
class Grandchild < Child
  prepend Tens
  def go
    super() { |x| x + 2 }
  end
end
p Grandchild.new.go

class Between < Parent
end

class Below < Between
  prepend Tens
  def go
    super() { |x| x + 3 }
  end
end
p Between.new.go
p Below.new.go

# the child prepends another module than the parent, and the parent two
module Marks
  def go
    super() { |x| x + 5 } << :marks
  end
end

class Other < Parent
  prepend Marks
  def go
    super() { |x| x + 1 }
  end
end
p Other.new.go

class Twice
  prepend Tens
  prepend Marks
  def go
    r = []
    r << (yield 1)
    r << (yield 2)
    r
  end
end

class UnderTwice < Twice
  prepend Tens
  def go
    super() { |x| x + 1 }
  end
end
p Twice.new.go
p UnderTwice.new.go

# with arguments, and the parent's value changed on the way back
module Scaled
  def from(n)
    super(n * 10) { |x| x + 1000 }
  end
end

class Counter
  prepend Scaled
  def from(n)
    r = []
    r << (yield n)
    r << (yield n + 1)
    r
  end
end

class Reversed < Counter
  prepend Scaled
  def from(n)
    super(n + 1) { |x| x + 7 }.reverse
  end
end
p Counter.new.from(1)
p Reversed.new.from(1)

# a module that both classes prepend, named again in the lower class: it
# runs once for each class
module Marked
  def go
    v = super() { |x| x * 3 }
    [v, :m]
  end
end

class Upper
  prepend Marked
  def go
    r = []
    r << (yield 1)
    r << (yield 2)
    r
  end
end

class Lower < Upper
  prepend Marked
end
class Lower
  prepend Marked
  def go
    super
  end
end
p Lower.new.go

class LowerTwice < Upper
  prepend Marked
  prepend Marked
end
p LowerTwice.new.go

class LowerMixed < Upper
  prepend Marked
  include Marked
  def go
    super
  end
end
p LowerMixed.new.go
