# A String computed from an element of an Array of mutable Strings and
# stored back is the Array's own String, as in CRuby: a later change
# through a method's answer, or through the element, reaches the Array.
# The store's value is boxed, and it was stored as a plain String that no
# later change reached.

class C
  attr_reader :xs
  def initialize
    @xs = [+"az"]
  end
  def succ_head
    @xs[0] = @xs[0].succ
    @xs[0]
  end
  def plus_head
    @xs[0] = @xs[0] + "q"
    @xs[0]
  end
  def up_head
    @xs[0] = @xs[0].upcase
    @xs[0]
  end
  def local_head
    x = @xs[0].succ
    @xs[0] = x
    @xs[0]
  end
  def put(v)
    @xs[0] = v
    @xs[0]
  end
end

c = C.new; c.succ_head.succ!; p c.xs
c = C.new; c.succ_head << "x"; p c.xs
c = C.new; c.succ_head.upcase!; p c.xs
c = C.new; r = c.succ_head.succ!; p r, c.xs
c = C.new; c.succ_head; c.xs[0].succ!; p c.xs
c = C.new; c.plus_head << "x"; p c.xs
c = C.new; c.up_head.succ!; p c.xs
c = C.new; c.local_head << "x"; p c.xs

# twice over, and what the Array answers afterwards
c = C.new; c.succ_head; c.succ_head << "!"; p c.xs, c.xs.join, c.xs.include?("bb!")

# a copy of the Array taken first keeps what it had
c = C.new; c.succ_head; d = c.xs.dup; c.succ_head << "x"; p d, c.xs

# a value in the slot that is no String passes as it is
c = C.new
c.put(41); p c.succ_head, c.xs
c.put(nil); p c.xs
c.put(+"ay"); c.succ_head << "!"; p c.xs
