# `s.n += 1`, `s.m ||= v` and `@m ||= v` on a frozen object raise FrozenError,
# as `s.n = v` does, after the right side and the operator have run. An
# or-write that stores nothing raises nothing.
def boom = raise(ArgumentError, "right side")

def loud(x)
  puts "loud #{x}"
  x
end

def leave(x)
  throw :out, x if x == x
  x
end

def bye(x)
  puts "bye"
  exit 0 if x == x
  x
end

class Acc
  attr_accessor :n, :m, :t, :f, :a

  def initialize
    @n = 0
    @t = "x"
    @f = 1.5
    @a = [1]
  end

  def memo = (@m ||= 7)

  def memo_boom = (@m ||= boom)

  def memo_stmt
    @m ||= 8
    nil
  end

  def bump
    self.n += 1
    nil
  end
end

s = Acc.new
s.freeze

# an operator-assign as a statement: an Integer, a String, a Float, an Array
begin; s.n += 1; puts "no raise"; rescue FrozenError => e; puts e.class; end
begin; s.n |= 2; puts "no raise"; rescue FrozenError => e; puts e.class; end
begin; s.n <<= 1; puts "no raise"; rescue FrozenError => e; puts e.class; end
begin; s.t += "y"; puts "no raise"; rescue FrozenError => e; puts e.class; end
begin; s.f += 1.0; puts "no raise"; rescue FrozenError => e; puts e.class; end
begin; s.a += [2]; puts "no raise"; rescue FrozenError => e; puts e.class; end
# and with its value used
begin; x = (s.n += 1); p x; rescue FrozenError => e; puts e.class; end

# `||=` and `&&=`: the two that store raise, the two that do not are quiet
begin; s.m ||= 5; puts "no raise"; rescue FrozenError => e; puts e.class; end
begin; s.n &&= 5; puts "no raise"; rescue FrozenError => e; puts e.class; end
begin; s.n ||= 5; puts "no raise"; rescue FrozenError => e; puts e.class; end
begin; s.m &&= 5; puts "no raise"; rescue FrozenError => e; puts e.class; end
begin; y = (s.m ||= 6); p y; rescue FrozenError => e; puts e.class; end

# in the object's own methods
begin; s.memo; puts "no raise"; rescue FrozenError => e; puts e.class; end
begin; s.memo_stmt; puts "no raise"; rescue FrozenError => e; puts e.class; end
begin; s.bump; puts "no raise"; rescue FrozenError => e; puts e.class; end
p s.n, s.m, s.t, s.f, s.a

# a Struct
P = Struct.new(:n, :m)
q = P.new(0, nil)
q.freeze
begin; q.n += 1; puts "no raise"; rescue FrozenError => e; puts e.class; end
begin; q.m ||= 5; puts "no raise"; rescue FrozenError => e; puts e.class; end
p q.to_a

# a String slot that another name appends to
class Note
  attr_accessor :s

  def initialize = @s = +"ab"

  def more = (@s &&= +"ef")
end
b = Note.new
k = b.s
k << "x"
b.freeze
begin; b.s &&= +"cd"; puts "no raise"; rescue FrozenError => e; puts e.class; end
begin; b.more; puts "no raise"; rescue FrozenError => e; puts e.class; end
p b.s

# an object of the class that is not frozen is written as before
u = Acc.new
u.n += 1
u.m ||= 5
u.memo
u.bump
p u.n, u.m

# a receiver whose class is known only at run time
class Base
  attr_accessor :n

  def initialize = @n = 0
end

class Sub < Base
end

class Other
  attr_accessor :n

  def initialize = @n = 0
end

def bump(o)
  o.n += 1
  nil
end

def bump_by(o, d)
  o.n += loud(d)
  nil
end
z = Sub.new
z.freeze
o = Other.new
begin; bump(z); puts "no raise"; rescue FrozenError => e; puts e.class; end
bump(o)
bump(Base.new)
p z.n, o.n

# Ruby runs the right side and the operator before the writer raises: one
# that raises has raised, one that prints has printed
zero = 0
begin; s.n += boom; puts "no raise"; rescue => e; puts e.class; end
begin; s.m ||= boom; puts "no raise"; rescue => e; puts e.class; end
begin; s.memo_boom; puts "no raise"; rescue => e; puts e.class; end
begin; s.n += 1 / zero; puts "no raise"; rescue => e; puts e.class; end
begin; s.n /= zero; puts "no raise"; rescue => e; puts e.class; end
begin; s.n += loud(1); puts "no raise"; rescue => e; puts e.class; end
begin; s.m ||= loud(2); puts "no raise"; rescue => e; puts e.class; end
begin; bump_by(z, 3); puts "no raise"; rescue => e; puts e.class; end
bump_by(o, 4)
p s.n, s.m, z.n, o.n

# a right side that freezes the receiver
w = Acc.new
begin; w.n += (w.freeze; 1); puts "no raise"; rescue => e; puts e.class; end
w = Acc.new
begin; w.m ||= (w.freeze; 2); puts "no raise"; rescue => e; puts e.class; end
p w.n, w.m

# a right side that throws, leaves its block with `next`, or exits
r = catch(:out) do
  s.n += leave(7)
  0
end
p r
r = catch(:out) do
  s.m ||= leave(8)
  0
end
p r
[1, 2].each do |i|
  s.n += (next if i == 1; i)
  puts "not reached"
rescue FrozenError => e
  puts "#{i} #{e.class}"
end
p s.n, s.m
s.n += bye(1)
puts "not reached"
