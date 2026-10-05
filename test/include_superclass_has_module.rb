# `include M` in a class whose superclass includes M already adds nothing:
# M is in the class's chain once, behind that superclass. The module's
# methods were copied into the subclass a second time, so a method of M
# that calls super ran twice for it: `Child.new.count` below answered 3
# for 2.
module Plus
  def count
    super + 1
  end

  def label
    "plus"
  end
end

class Root
  def count
    1
  end
end

class Parent < Root
  include Plus
end

class Child < Parent
  include Plus
end

class Grandchild < Child
  include Plus
end
p Parent.new.count
p Child.new.count
p Grandchild.new.count
puts Grandchild.new.label

# the subclass's own method still reaches the module's through super
class Scaled < Parent
  include Plus
  def count
    super * 10
  end
end
p Scaled.new.count

# another module on the subclass goes in front, once
module Hundred
  def count
    super + 100
  end
end

class Mixed < Parent
  include Hundred
  include Plus
end
p Mixed.new.count

# a class with no include between the two
class Between < Parent
end

class Below < Between
  include Plus
end
p Below.new.count

# the superclass has the module through another module
module Wrap
  include Plus
end

class ViaWrap < Root
  include Wrap
end

class UnderWrap < ViaWrap
  include Plus
end
p ViaWrap.new.count
p UnderWrap.new.count

# a block given to super in the module's method runs once
module Tripled
  def each_two
    v = super() { |x| x * 3 }
    [v, :tripled]
  end
end

class Yielder
  def each_two
    r = []
    r << (yield 1)
    r << (yield 2)
    r
  end
end

class First < Yielder
  include Tripled
end

class Second < First
  include Tripled
end
p First.new.each_two
p Second.new.each_two

# the class includes it before its superclass does: then it is there twice
class Late < Root
end

class Early < Late
  include Plus
end

class Late
  include Plus
end
p Late.new.count
p Early.new.count

# membership is unchanged
p Child.include?(Plus), Child.new.is_a?(Plus), Child.new.is_a?(Hundred)
