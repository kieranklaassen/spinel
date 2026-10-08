# A write to a frozen object runs its right-hand side, then raises
# FrozenError: `s.n = f`, `@n = f`, `self.n = f` and instance_variable_set,
# as a statement and as a value. On an object that is not frozen the same
# lines store.
class Rec
  attr_accessor :n, :s, :a

  def initialize
    @n = 0
    @s = "a"
    @a = [0]
  end

  def set_n
    @n = num(11)
    nil
  end

  def set_s
    @s = str(12)
    nil
  end

  def set_value
    x = (@n = num(13))
    x
  end

  def set_last = @a = arr(14)

  def set_self
    self.n = num(15)
    nil
  end
end

def num(x)
  puts "num #{x}"
  x
end

def str(x)
  puts "str #{x}"
  "s#{x}"
end

def arr(x)
  puts "arr #{x}"
  [x]
end

def yes(x)
  puts "yes #{x}"
  true
end

def try
  yield
  puts "stored"
rescue FrozenError => e
  puts e.class
end

def writes(r)
  # the writer, as a statement: an Integer, a String, an Array
  try { r.n = num(1) }
  try { r.s = str(2) }
  try { r.a = arr(3) }
  # the writer's value used
  try { x = (r.n = num(4)); p x }
  try { x = (r.s = str(5)); p x }
  # a value that chooses, and one a block makes
  try { r.n = (yes(6) ? num(7) : num(8)) }
  try { r.n = [9, 10].map { |i| num(i) }.last }
  # the instance variable in the object's own methods
  try { r.set_n }
  try { r.set_s }
  try { p r.set_value }
  try { p r.set_last }
  try { r.set_self }
  try { r.instance_variable_set(:@n, num(16)) }
  p r.n, r.s, r.a
end

frozen = Rec.new
frozen.freeze
writes(frozen)
writes(Rec.new)

# a right side that raises, throws, leaves its block or exits does so, and
# one that freezes the receiver is followed by FrozenError
def boom(x)
  raise ArgumentError, "right side" if x == x
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

begin; frozen.n = boom(1); puts "stored"; rescue => e; puts e.class; end
r = catch(:out) do
  frozen.n = leave(7)
  0
end
p r
[1, 2].each do |i|
  frozen.n = (next if i == 1; num(i))
  puts "not reached"
rescue FrozenError => e
  puts "#{i} #{e.class}"
end
w = Rec.new
begin; w.n = (w.freeze; 1); puts "stored"; rescue => e; puts e.class; end
p frozen.n, w.n
frozen.n = bye(1)
puts "not reached"
