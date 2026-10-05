# `include M` in a class that has M prepended already adds nothing, and
# neither does it in a subclass of a class that prepends M: M is in the
# chain, in front of the class that prepended it. The include copied the
# module's methods behind the class all the same, so a method of M that
# calls super ran once more: `Mixed.new.trail` below answered
# [:root, :m, :own, :m] for [:root, :own, :m].
module Mark
  def trail
    super + [:m]
  end
end

class Root
  def trail
    [:root]
  end
end

class Mixed < Root
  prepend Mark
  include Mark
  def trail
    super + [:own]
  end
end
p Mixed.new.trail

# the include in a reopening of the class
class Reopened < Root
  prepend Mark
  def trail
    super + [:own]
  end
end
class Reopened
  include Mark
end
p Reopened.new.trail

# the prepend in the superclass, the include in a subclass and in its subclass
class Parent < Root
  prepend Mark
  def trail
    super + [:parent]
  end
end

class Child < Parent
  include Mark
  def trail
    super + [:child]
  end
end

class Grandchild < Child
  include Mark
end
p Child.new.trail
p Grandchild.new.trail
p Child.new.is_a?(Mark), Child.include?(Mark)

# `include M, N` where only M is prepended above: N is included
module Note
  def trail
    super + [:n]
  end
end

class Noted < Parent
  include Mark, Note
  def trail
    super + [:noted]
  end
end
p Noted.new.trail

# included first and prepended after, the module is in the chain twice
class Both < Root
  include Mark
  prepend Mark
  def trail
    super + [:own]
  end
end
p Both.new.trail

# so it is where the superclass prepends it only after the subclass's include
class Early < Root
  def trail
    super + [:early]
  end
end
class Late < Early
  include Mark
  def trail
    super + [:late]
  end
end
class Early
  prepend Mark
end
p Late.new.trail

# a module that keeps a count
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

class CountedTwice < Counter
  prepend Counted
  include Counted
end
c = CountedTwice.new
p c.bump
p c.bump
