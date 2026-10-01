# The roots a method registers for its parameters and locals, and when it may
# register none.
#
# A method that calls nothing that could collect is never on the stack while
# the collector looks for roots, so it registers none: `link` and `link_both`
# below only store. A method that can collect must keep every one. Each of the
# others makes a value that only its own frame names, collects, and then
# allocates another of the same size, which is handed the slot of a value that
# was not rooted -- and the numbers and strings printed come out wrong.
#
# `spelled` and `label` hold strings that spell a root. Taking a method's
# roots back must not take part of a string with them.

class Thing
  attr_accessor :v, :peer, :other, :tag
  def initialize(v)
    @v = v
    @peer = nil
    @other = nil
  end

  def link(a)
    @peer = a
  end

  def link_both(a, b)
    @peer = a
    @other = b
  end

  def spelled
    "SP_GC_ROOT(self); is how a root is spelled"
  end

  def label(a)
    @peer = a
    @tag = "SP_GC_ROOT"
  end

  def relink(a)
    a = Thing.new(a.v + 1)
    GC.start
    b = Thing.new(900)
    @peer = a
    @other = b
  end
end

def rebuild(a)
  a = Thing.new(a.v + 1)
  GC.start
  b = Thing.new(900)
  a.v * 1000 + b.v
end

def relabel(s, n)
  s = s + n.to_s
  GC.start
  t = "zz" + n.to_s
  s + "/" + t
end

root = Thing.new(0)
things = []
40.times do |i|
  t = Thing.new(i)
  t.link(root)
  t.link_both(Thing.new(i + 100), Thing.new(i + 200))
  things << t
  GC.start if i % 10 == 0
end
puts things.map { |t| t.v + t.peer.v + t.other.v }.sum

puts (1..5).map { |i| rebuild(Thing.new(i)) }.join(" ")
puts (1..5).map { |i| relabel("ab", i) }.join(" ")

holders = []
5.times do |i|
  h = Thing.new(i)
  h.relink(Thing.new(i * 7))
  holders << h
end
puts holders.map { |h| h.peer.v * 1000 + h.other.v }.join(" ")

named = Thing.new(1)
named.label(root)
puts named.spelled
puts named.tag + " " + named.peer.v.to_s
