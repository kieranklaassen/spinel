# An append through delegating readers reaches the String when the method
# that holds it is first met at the walk's depth bound. Each method is
# walked once per demand; one first met at the bound had its own result
# cut there, and the shorter route to it was then skipped as walked, so
# the append went to a copy and `bus.peek(0)` still read "leaf".

# Four pass-through classes declared ahead of the one that reads through
# a helper: by name, Ram#peek is first met four levels down.
class Dev1
  def initialize(nxt) = @nxt = nxt
  def peek(i) = @nxt.peek(i)
end

class Dev2
  def initialize(nxt) = @nxt = nxt
  def peek(i) = @nxt.peek(i)
end

class Dev3
  def initialize(nxt) = @nxt = nxt
  def peek(i) = @nxt.peek(i)
end

class Dev4
  def initialize(nxt) = @nxt = nxt
  def peek(i) = @nxt.peek(i)
end

class Ram
  def initialize = @v = [+"leaf", +"two"]
  def peek(i) = cell(i)
  def cell(i) = @v[i]
end

a = Dev1.new(Dev2.new(Dev3.new(Dev4.new(Ram.new))))
b = Dev4.new(Dev3.new(Dev2.new(Dev1.new(Ram.new))))
[a, b].each do |bus|
  bus.peek(0) << "!"
  bus.peek(1).upcase!
  p bus.peek(0), bus.peek(1)
end

# One class, two routes of different length to the same method: the long
# one is the method's last expression and is walked first.
class Bus
  def initialize = @v = [+"leaf", +"two"]
  def cell(i) = @v[i]
  def m4(i) = cell(i)
  def m3(i) = m4(i)
  def m2(i) = m3(i)
  def m1(i) = m2(i)

  def peek(i)
    return m4(i) if i > 5
    m1(i)
  end
end

bus = Bus.new
bus.peek(0) << "!"
bus.peek(1) << "?"
p bus.peek(0), bus.peek(1)
