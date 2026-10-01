# The barrier on a store into an object that is still being built.
#
# A new object is young, and a store into a young object needs no barrier. An
# initialize that cannot collect and is only ever run by `new`, on the object
# `new` has just allocated, therefore stores bare: Pair, and Trunk with the
# Branch that inherits its initialize. One other way in and the barriers stay,
# because the object may have aged by then: Slot runs its initialize again on
# itself, and Base's is reached through `super`. Slot is the case that fails
# when they are dropped anyway -- it is old by the time it is refilled with
# two new leaves, and the collector's verifier reports the holder nobody
# recorded.
#
# Note stores a string that spells both shapes a barrier is written in. It is
# a string: its initialize stores bare and the text comes back whole.

class Leaf
  attr_reader :v
  def initialize(v)
    @v = v
  end
end

class Pair
  attr_reader :a, :b
  def initialize(a, b)
    @a = a
    @b = b
  end
end

class Slot
  attr_reader :a, :b
  def initialize(a, b)
    @a = a
    @b = b
  end

  def refill(a, b)
    initialize(a, b)
    self
  end
end

class Trunk
  attr_reader :item
  def initialize(item)
    @item = item
  end
end

class Branch < Trunk
end

class Base
  attr_reader :item
  def initialize(item)
    @item = item
  end
end

class Derived < Base
  attr_reader :extra
  def initialize(item, extra)
    super(item)
    @extra = extra
  end
end

class Note
  attr_reader :leaf, :text
  def initialize(leaf)
    @leaf = leaf
    @text = "SP_WBO(self)->iv_leaf = leaf; { __typeof__(self) _wb1 = self; _wb1->iv_leaf = leaf; sp_gc_wb((void *)_wb1); }"
  end
end

def churn(n)
  junk = []
  n.times { |i| junk << Leaf.new(i) }
  junk.length
end

pairs = []
200.times { |i| pairs << Pair.new(Leaf.new(i), Leaf.new(i + 1)) }
puts pairs.map { |p| p.a.v + p.b.v }.sum

slots = []
10.times { |i| slots << Slot.new(Leaf.new(i), Leaf.new(i)) }
churn(500)
slots.each_with_index { |s, i| s.refill(Leaf.new(i * 100), Leaf.new(i * 100 + 1)) }
churn(500)
puts slots.map { |s| s.a.v + s.b.v }.join(" ")

limbs = []
50.times { |i| limbs << (i.even? ? Trunk.new(Leaf.new(i)) : Branch.new(Leaf.new(i * 2))) }
churn(200)
puts limbs.map { |l| l.item.v }.sum

kin = []
50.times { |i| kin << Derived.new(Leaf.new(i), Leaf.new(i * 3)) }
churn(200)
puts kin.map { |d| d.item.v + d.extra.v }.sum

notes = []
3.times { |i| notes << Note.new(Leaf.new(i)) }
puts notes.map { |n| n.leaf.v }.sum
puts notes[0].text
