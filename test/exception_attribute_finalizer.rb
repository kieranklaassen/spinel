# An attribute of an exception class with no initialize, in a program with a
# finalizer. The collector runs the block when it chooses, so the object is
# built as before: a slot the block is to store 0 in reads 0 whether or not
# the block has run yet.
class Counted < StandardError
  attr_accessor :count
end

class Sweep
  def self.arm(e)
    100.times { ObjectSpace.define_finalizer("x".dup, proc { e.count = 0 }) }
  end
end

e = Counted.new("m")
Sweep.arm(e)
GC.start
p e.count
p e.message
