# `prepend M` in a class that has M prepended already adds nothing: M stays
# in front of the class once. Each `prepend` statement copied the module's
# methods in front of the class again, so a method of M that calls super
# ran once for each: `Twice.new.trail` below answered [:root, :own, :m, :m]
# for [:root, :own, :m].
module Mark
  def trail
    super + [:m]
  end
end

module Note
  def trail
    super + [:n]
  end
end

class Root
  def trail
    [:root]
  end
end

class Twice < Root
  prepend Mark
  prepend Mark
  def trail
    super + [:own]
  end
end
p Twice.new.trail
p Twice.ancestors.first(3)

# the same module three times, and twice in one call
class Thrice < Root
  prepend Mark
  prepend Mark
  prepend Mark
end
p Thrice.new.trail

class OneCall < Root
  prepend Mark, Mark
  def trail
    super + [:own]
  end
end
p OneCall.new.trail

# a class reopened with the prepend again, its method in either body
class Reopened < Root
  prepend Mark
  def trail
    super + [:own]
  end
end
class Reopened
  prepend Mark
end
p Reopened.new.trail

class Later < Root
  prepend Mark
end
class Later
  prepend Mark
  def trail
    super + [:own]
  end
end
p Later.new.trail

# another module between: the second `prepend Mark` does not move it
class Between < Root
  prepend Mark
  prepend Note
  prepend Mark
  def trail
    super + [:own]
  end
end
p Between.new.trail
p Between.ancestors.first(4)

# a method of the module that keeps a count, and one that gives super a block
module Counted
  def bump
    @bumps = (@bumps || 0) + 1
    super + @bumps
  end
end

class Counter
  def bump
    10
  end
end

class TwiceCounted < Counter
  prepend Counted
  prepend Counted
end
c = TwiceCounted.new
p c.bump
p c.bump

module Triple
  def each_pair
    super() { |x| x * 3 }
  end
end

class Pairs
  def each_pair
    r = []
    r << (yield 1)
    r << (yield 2)
    r
  end
end

class TwicePairs < Pairs
  prepend Triple
  prepend Triple
end
p TwicePairs.new.each_pair

# a module that does not call super, and a second class with one prepend
module Shout
  def trail
    [:shout]
  end
end

class Loud < Root
  prepend Shout
  prepend Shout
  def trail
    super + [:own]
  end
end
p Loud.new.trail

class Once < Root
  prepend Mark
  def trail
    super + [:own]
  end
end
p Once.new.trail

# a module included and then prepended is in the chain twice
class Both < Root
  include Mark
  prepend Mark
  def trail
    super + [:own]
  end
end
p Both.new.trail
