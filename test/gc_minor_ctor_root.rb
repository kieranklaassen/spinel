# The root a constructor holds on the object it is building, and when it may
# go without one.
#
# Until `new` returns, the constructor is the only thing that names the new
# object, so it roots `self` across initialize. An initialize that only stores
# cannot collect, and its constructor drops the root. One that can collect --
# by allocating, by calling a method that does, or through a parent's
# initialize -- must keep it: here each such initialize collects and then
# allocates an object of its own size, which is handed the slot of an unrooted
# `self`, and the values printed come out wrong.

class Leaf
  attr_reader :v, :tag
  def initialize(v)
    @v = v
    @tag = "leaf"
  end
end

class Twig < Leaf
end

class Cell
  attr_reader :v, :peer, :pad
  def initialize(v, depth)
    @v = v
    @pad = nil
    GC.start
    @peer = depth > 0 ? Cell.new(v + 1000, depth - 1) : nil
  end
end

class Maker
  attr_reader :n, :made
  def initialize(n)
    @n = n
    @made = build(n)
  end

  def build(n)
    GC.start
    Leaf.new(n + 500)
  end
end

class Heir < Cell
  attr_reader :w
  def initialize(v)
    super(v, 1)
    @w = v * 2
  end
end

def chain(c)
  out = []
  while c
    out << c.v
    c = c.peer
  end
  out
end

cells = []
6.times { |i| cells << Cell.new(i, 3) }
cells.each { |c| puts chain(c).join(" ") }

leaves = []
200.times do |i|
  leaves << (i.odd? ? Twig.new(i) : Leaf.new(i))
  GC.start if i % 50 == 0
end
puts leaves.map { |l| l.v + l.tag.length }.sum

makers = []
8.times { |i| makers << Maker.new(i) }
puts makers.map { |m| m.n * 10000 + m.made.v }.join(" ")

heirs = []
5.times { |i| heirs << Heir.new(i + 1) }
puts heirs.map { |h| chain(h).join("-") + "/" + h.w.to_s }.join(" ")
