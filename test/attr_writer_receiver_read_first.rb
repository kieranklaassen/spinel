# `recv.x = value` reads its receiver before the value runs, and stores
# into the object it read.
#
# A receiver that is a plain read (a local, a global, an instance or class
# variable, a field read off one) was read where the store is written. A
# value that assigned the variable another object stored into that one; a
# value that assigned it nil and then allocated left the receiver to
# nothing, and the store went into whatever took its slot.
class K
  attr_accessor :v
  def initialize(v) = @v = v
end
class L
  attr_accessor :v
  def initialize(v) = @v = v
end
# a slot that only ever holds an Integer: its store is one C assignment
class N
  attr_accessor :n
  def initialize(n) = @n = n
end
def mk8 = Array.new(8) { |i| K.new("k#{i}") }
def intact(made)
  ok = true
  made.each_with_index { |k, i| ok = false unless k.v == "k#{i}" }
  ok
end

class NHolder
  @@held = nil
  def initialize(held) = @held = held
  def ivar(b)
    @held.n = (@held = b; 2)
    nil
  end
  def self.cvar(a, b)
    @@held = a
    @@held.n = (@@held = b; 3)
    nil
  end
  # the assignment is in a method the value calls
  def swap(b)
    @held = b
    6
  end
  def by_call(b)
    @held.n = swap(b)
    nil
  end
end
def swap_global(b)
  $g = b
  7
end
class Holder
  attr_accessor :o
  @@o = nil
  def initialize(o) = @o = o
  def ivar_gone(r)
    @o = K.new("v")
    @o.v = (@o = nil; made = mk8; r)
    intact(made)
  end
  def field_gone(r)
    @o = K.new("v")
    self.o.v = (@o = nil; made = mk8; r)
    intact(made)
  end
  def self.cvar_gone(r)
    @@o = K.new("v")
    @@o.v = (@@o = nil; made = mk8; r)
    intact(made)
  end
end
# A writer statement asks what a method assigns. `take` assigns @o in the
# value of a store that is itself read for its value, and a writer statement
# in that store's receiver asks about `take` first: the later `@o.n =
# take(b)` gets the same answer.
class Slot
  def initialize = @state = 0
  def state=(v)
    @state = v
  end
end
class Asked
  def initialize(o)
    @o = o
    @s = Slot.new
    @z = N.new(9)
    @d = 0
  end
  def claim
    yield
    @s
  end
  def take(b)
    @d += 1
    return 0 if @d > 1
    x = (claim { @z.n = take(b) }.state = (@o = b; 8))
    x
  end
  def go(a, b)
    @o = a
    @o.n = take(b)
    nil
  end
end

# the value rebinds what the receiver reads: the first object takes the store
a = N.new(0); b = N.new(0)
c = a
c.n = (c = b; 1)
p [a.n, b.n]
a = N.new(0); b = N.new(0)
NHolder.new(a).ivar(b)
p [a.n, b.n]
a = N.new(0); b = N.new(0)
NHolder.cvar(a, b)
p [a.n, b.n]
a = N.new(0); b = N.new(0)
$g = a
$g.n = ($g = b; 4)
p [a.n, b.n]
a = N.new(0); b = N.new(0)
c = a
(0; c).n = (c = b; 5)
p [a.n, b.n]
a = N.new(0); b = N.new(0)
NHolder.new(a).by_call(b)
p [a.n, b.n]
a = N.new(0); b = N.new(0)
$g = a
$g.n = swap_global(b)
p [a.n, b.n]
a = N.new(0); b = N.new(0)
Asked.new(a).go(a, b)
p [a.n, b.n]

# the value assigns the variable nil, then allocates
bad = [0] * 6
h = Holder.new(nil)
300.times do |r|
  o = K.new("v")
  o.v = (o = nil; made = mk8; r)
  bad[0] += 1 unless intact(made)
  bad[1] += 1 unless h.ivar_gone(r)
  bad[2] += 1 unless h.field_gone(r)
  bad[3] += 1 unless Holder.cvar_gone(r)
  o = K.new("v")
  (0; o).v = (o = nil; made = mk8; r)
  bad[4] += 1 unless intact(made)
  # a receiver of either of two classes
  e = r.odd? ? L.new("w") : K.new("v")
  e.v = (e = nil; made = mk8; "w")
  bad[5] += 1 unless intact(made)
end
p bad
