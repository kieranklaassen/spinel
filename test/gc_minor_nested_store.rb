# A store in the value of another store takes its write barrier.
#
# `k.w = @last.w = v` is one C statement, and so is
# `@seen = @items.each { |it| it.w = v }` with the whole block inside it. The
# barrier pass rewrote the outer store and went on from the end of the
# statement, so a store inside the value got no barrier: a young value held
# only by an old holder was freed while still in the slot, and read back as
# whatever the slot was handed to next.
#
# Every case stores a fresh value into a holder that is old, drops the other
# reference, allocates, and reads the value back. Each line is the number of
# rounds that read back something else:
#
#   * a chained assignment of an Array, a String, an object and a Hash
#   * the same under an instance variable write, a ternary, `||` and `||=`
#   * three stores deep
#   * in a block that is the value of a store
#   * in a method that yields and in an initialize that takes a block, which
#     are expanded where they are called, so their own stores land in the
#     value of the caller's store
#   * two captured locals in a lambda, `x = y = v`
#
# The last lines are an interpolated String in such a value, whose written
# pieces spell a store and are in the statement's C as text: it comes back as
# it was written.
#
# The gc-minor-test leg also runs this under SPINEL_GC_VERIFY_GEN=1
# SPINEL_GC_STRESS=1, which reports the holder that went unrecorded.

class Slot
  attr_accessor :ary, :str, :obj, :hsh
  attr_reader :v
  def initialize(v)
    @v = v
    @ary = nil
    @str = nil
    @obj = nil
    @hsh = nil
  end
end

def churn(n)
  i = 0
  x = nil
  while i < n
    x = [Slot.new("c#{i}"), "d#{i}"]
    i += 1
  end
  x
end

class Box
  attr_reader :data
  def initialize(a, b, pad)
    churn(pad)   # a collection here leaves the new object old at its own store
    @data = [Slot.new(a), Slot.new(b)]
    yield self
  end
end

class Owner
  attr_writer :pad

  def initialize
    @box = nil
    @pad = 0
    @last = Slot.new("last")
    @far = Slot.new("far")
    @items = [Slot.new("item")]
    @none = nil
    @x = nil
    @seen = nil
    x = nil
    y = nil
    @set = ->(a, b) { x = y = [Slot.new(a), Slot.new(b)]; x = nil; nil }
    @get = -> { y }
    s = nil
    t = nil
    @set_text = ->(a, b) { s = t = "(*_cell_t) = '#{a}' \"#{b}"; s = nil; nil }
    @get_text = -> { t }
  end

  def fill(a, b)
    @last.ary = [Slot.new(a), Slot.new(b)]
    yield a
  end

  def pair?(w, a, b)
    w.size == 2 && w[0].v == a && w[1].v == b
  end

  def set(which, a, b)
    k = Slot.new(a)
    case which
    when 0 then k.ary = @last.ary = [Slot.new(a), Slot.new(b)]
    when 1 then k.str = @last.str = a + b
    when 2 then k.obj = @last.obj = Slot.new(a + b)
    when 3 then k.hsh = @last.hsh = { "p" => Slot.new(a), "q" => Slot.new(b) }
    when 4
      @x = @last.ary = [Slot.new(a), Slot.new(b)]
      @x = nil
    when 5
      @x = a.size > 0 ? (@last.ary = [Slot.new(a), Slot.new(b)]) : nil
      @x = nil
    when 6
      @x = @none || (@last.ary = [Slot.new(a), Slot.new(b)])
      @x = nil
    when 7
      @x ||= (@last.ary = [Slot.new(a), Slot.new(b)])
      @x = nil
    when 8 then k.ary = @last.ary = @far.ary = [Slot.new(a), Slot.new(b)]
    when 9 then @seen = @items.each { |it| it.ary = [Slot.new(a), Slot.new(b)] }
    when 10 then @set.call(a, b)
    when 11 then k.str = @last.str = "q->iv_str = '#{a}' \"#{b}"
    when 12 then @set_text.call(a, b)
    when 13 then @x = fill(a, b) { |q| q.size }
    when 14 then @box = Box.new(a, b, @pad) { |bx| bx }
    end
    nil
  end

  def ok?(which, a, b)
    case which
    when 1 then @last.str == a + b
    when 2 then @last.obj.v == a + b
    when 3 then @last.hsh["p"].v == a && @last.hsh["q"].v == b
    when 8 then pair?(@last.ary, a, b) && pair?(@far.ary, a, b)
    when 9 then pair?(@items[0].ary, a, b)
    when 10 then pair?(@get.call, a, b)
    when 11 then @last.str == "q-" + ">iv_str = '" + a + "' \"" + b
    when 12 then @get_text.call == "(*_cell" + "_t) = '" + a + "' \"" + b
    when 14 then pair?(@box.data, a, b)
    else pair?(@last.ary, a, b)
    end
  end

  def text(which)
    which == 11 ? @last.str : @get_text.call
  end
end

def rounds(o, which, n, gap)
  o.pad = gap
  bad = 0
  r = 0
  while r < n
    a = "a#{r}"
    b = "b#{r}"
    o.set(which, a, b)
    churn(gap)
    bad += 1 unless o.ok?(which, a, b)
    r += 1
  end
  bad
end

# Long gaps first, for a plain run, where a collection takes thousands of
# allocations; then short ones for the leg's stress run, where a few do.
def wrong_rounds(which)
  o = Owner.new
  churn(5000)   # the owner and its holders are old from here on
  bad = rounds(o, which, 60, 1500) + rounds(o, which, 600, 30)
  puts o.text(which) if which == 11 || which == 12
  bad
end

puts "chained, an Array: #{wrong_rounds(0)}"
puts "chained, a String: #{wrong_rounds(1)}"
puts "chained, an object: #{wrong_rounds(2)}"
puts "chained, a Hash: #{wrong_rounds(3)}"
puts "under an instance variable write: #{wrong_rounds(4)}"
puts "in a ternary: #{wrong_rounds(5)}"
puts "after ||: #{wrong_rounds(6)}"
puts "after ||=: #{wrong_rounds(7)}"
puts "three deep: #{wrong_rounds(8)}"
puts "in a block: #{wrong_rounds(9)}"
puts "in a method that yields: #{wrong_rounds(13)}"
puts "in an initialize that takes a block: #{wrong_rounds(14)}"
puts "two captured locals: #{wrong_rounds(10)}"
puts "a String that spells a store: #{wrong_rounds(11)}"
puts "a String that spells a captured local's store: #{wrong_rounds(12)}"
