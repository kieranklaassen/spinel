# `k.new(...)` on a Class value builds some of the constructor's values
# itself: a fresh argument, a default the call leaves out, an empty **kw.
# Nothing held them, and the next one's allocation, or the constructor's
# own of the object, collected them.
class One
  def initialize(x)
    @v = [x]
  end
  def v = @v
end
class Dflt
  def initialize(x, y = "c" * 2, z = "d" * 2)
    @v = [x, y, z]
  end
  def v = @v
end
class Lit
  def initialize(x, o = {}, l = [])
    @v = [x, o.size, l]
  end
  def v = @v
end
class Keyed
  def initialize(x, k: "k" * 2)
    @v = [x, k]
  end
  def v = @v
end
class Kwr
  def initialize(x, **kw)
    @v = [x, kw.size]
  end
  def v = @v
end
class Oops < StandardError
  def initialize(msg = "o" * 2) = super
end
class Other < StandardError
  def initialize(msg = "p" * 2) = super
end

s = "q" * 2
# the class read out of an Array
one = [One, Kwr][0]
p one.new("z" * 2).v
p [One, Kwr][1].new("z" * 2).v
p [Dflt, One][0].new(1).v
p [Dflt, One][0].new("z" * 2).v
p [Lit, One][0].new(1).v
p [Keyed, One][0].new(1).v
p [Keyed, One][0].new("z" * 2).v
p [Kwr, One][0].new(1).v
# the class picked by a condition
k = ARGV.empty? ? Dflt : One
p k.new(1).v, k.new("z" * 2).v
k = ARGV.empty? ? Lit : One
p k.new(1).v
k = ARGV.empty? ? Kwr : One
p k.new(1).v
# raise with the class in a variable
e = [Oops, Other][0]
begin
  raise e
rescue => err
  p err.message
end
p s

# a class's own `new` reached through the value
class Made
  def self.new(x, y = "c" * 2, z = "d" * 2) = [x, y, z]
end
class Kmade
  def self.new(x, k: "k" * 2, l: "l" * 2) = [x, k, l]
end
p [Made, Kmade][0].new(1)
p [Made, Kmade][1].new(1)

kl = [Dflt, One][0]
kept = []
n = 0
while n < 200
  kept << kl.new(n)
  n += 1
end
bad = 0
kept.each_with_index { |o, i| bad += 1 unless o.v == [i, "cc", "dd"] }
p bad

# a default to the left of one the arm binds runs ahead of it, positional
# and keyword
$log = []
def note(s) = ($log << s; s)
def bump(n) = ($log << n; n)
class Ord
  def initialize(x, y = bump(7), z = note("az") * 2)
    @v = [x, y, z]
  end
  def v = @v
end
class Kord
  def initialize(x, k: bump(8), l: note("kl") * 2, **o)
    @v = [x, k, l, o.size]
  end
  def v = @v
end
p [Ord, One][0].new(1).v, $log
$log.clear
p [Kord, One][0].new(1).v, $log
