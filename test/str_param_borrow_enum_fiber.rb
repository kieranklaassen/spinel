# A program has a fiber where it never calls Fiber.new: an Enumerator's
# `next` runs its block on one. A method that calls Fiber.yield there is
# paused while the caller of `next` runs, as it is under Fiber.new (#7674),
# so its String parameter keeps the copy. As in str_param_borrow_unseen.rb,
# each change grows the String past its buffer, restores it, and allocates
# buffers of the same size: the copy reads what CRuby reads, a freed buffer
# reads their bytes.

class Buf
  def initialize
    reset
  end

  # a String with a second name, in a buffer just big enough for it
  def reset
    @buf = +"abc"
    @buf << "d" * 1000
    b = @buf
    b << "e"
  end

  # grow past the buffer, restore, and reuse the freed memory
  def churn
    @buf << "x" * 100_000
    @buf.slice!(1004..)
    @junk = Array.new(32) { |i| j = +"Z"; j << "Z" * (900 + i); j }
    nil
  end

  def paused(s)
    Fiber.yield
    [s.bytesize, s.getbyte(0), s.getbyte(1003)]
  end

  def each
    yield paused(@buf)
  end

  def run_next
    reset
    e = Enumerator.new { |y| y << paused(@buf) }
    e.next
    churn
    e.next
  end

  def run_to_enum
    reset
    e = to_enum(:each)
    e.next
    churn
    e.next
  end
end

b = Buf.new
p b.run_next
p b.run_to_enum
