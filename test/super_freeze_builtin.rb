# `super` in a freeze or frozen? override that no ancestor defines is Object's:
# the object is frozen and answered, or its frozen flag read. The deep-freeze
# idiom (`@items.freeze; super`) raised NoMethodError for a missing superclass
# method, and a frozen? that asks super did not compile.
class Cart
  def initialize = @items = [1, 2]
  def items = @items
  def add(x) = @count = x
  def freeze
    @items.freeze
    super
  end
  def frozen? = super && @items.frozen?
end
c = Cart.new
p c.frozen?
r = c.freeze
p r.equal?(c)
p c.frozen?
p c.items.frozen?
p((c.add(3) rescue $!.class))

# through a parent, an included module and a prepended one
class Base
  def initialize = @n = 0
  def n = @n
  def freeze
    @n += 1
    super
  end
end
class Leaf < Base
  def freeze
    @n += 10
    super()
  end
end
l = Leaf.new
l.freeze
p l.n, l.frozen?
b = Base.new
p b.frozen?
b.freeze
p b.n, b.frozen?

module Sealing
  def freeze
    @sealed = true
    super
  end
  def sealed = @sealed
end
class Box
  include Sealing
end
class Crate
  prepend Sealing
  def freeze
    @inner = :done
    super
  end
  def inner = @inner
end
x = Box.new
x.freeze
p x.sealed, x.frozen?
y = Crate.new
p y.freeze.equal?(y)
p y.sealed, y.inner, y.frozen?

# a Struct and an exception
Pair = Struct.new(:a, :b) do
  def freeze
    self.b = a
    super
  end
  def frozen? = super
end
q = Pair.new(1, 2)
p q.frozen?
q.freeze
p q.b, q.frozen?
class Halt < StandardError
  def freeze
    @why = :frozen
    super
  end
  def why = @why
end
h = Halt.new("stop")
h.freeze
p h.why, h.frozen?, h.message

# the value of super kept, and a frozen? of its own beside the builtin freeze
class Flag
  def freeze
    r = super
    r
  end
  def frozen?
    f = super
    f
  end
end
f = Flag.new
p f.frozen?
p f.freeze.frozen?

# reached through an alias: the frozen object's own writes still raise
class Vault
  def initialize = @n = 0
  def n = @n
  def store(x) = @n = x
  def freeze
    @n += 1
    super
  end
  alias seal freeze
end
v = Vault.new
v.seal
p v.n
p((v.store(3) rescue $!.class))
p v.n
