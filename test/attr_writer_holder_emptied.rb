# The receiver of `recv.v = value` can be read out of something that keeps
# it: a class variable, a field of self, a local behind a sequence, an
# Array's element. A value that empties the holder before it allocates
# leaves the receiver to the writer's C temp alone. It was collected, and
# the store went into one of the objects the value had just made.
class K
  attr_accessor :v
  def initialize(v) = @v = v
end
def mk8 = Array.new(8) { |i| K.new("k#{i}") }
class M
  attr_accessor :o
  @@o = nil
  def self.cvar(r)
    @@o = K.new("v")
    @@o.v = (@@o = nil; made = mk8; r)
    made.all? { |k| k.v.is_a?(String) }
  end
  def field(r)
    @o = K.new("v")
    self.o.v = (@o = nil; made = mk8; r)
    made.all? { |k| k.v.is_a?(String) }
  end
end

m = M.new
bad = [0] * 4
5_000.times do |r|
  bad[0] += 1 unless M.cvar(r)
  bad[1] += 1 unless m.field(r)
  o = K.new("v")
  (0; o).v = (o = nil; made = mk8; r)
  bad[2] += 1 unless made.all? { |k| k.v.is_a?(String) }
  a = [K.new("v")]
  a[0].v = (a.clear; made = mk8; r)
  bad[3] += 1 unless made.all? { |k| k.v.is_a?(String) }
end
p bad
