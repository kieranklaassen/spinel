# A call that answers only nil, joined with a Float or an Integer: the slot's
# nil is nil wherever the value is boxed, stored or computed with.

def nothing(stop = false)
  raise "stop" if stop
  nil
end

class Box
  def nothing = nil
end

def show(v) = v.inspect
puts show("s")

# a conditional's other arm
def ternary(k)
  r = k ? 1.5 : nothing
  [r, 1]
end
p ternary(true)
p ternary(false)

# an if with an else, the call on a receiver
def if_else(k)
  r = if k then 1.5 else Box.new.nothing end
  [r, "x"]
end
p if_else(true)
p if_else(false)

# a second write, the value stored in a Hash
def rewritten(k)
  r = 1.5
  r = nothing unless k
  h = { a: r }
  h[:a].nil?
end
p rewritten(true)
p rewritten(false)

# a method's answer
def pick(k) = k ? 1.5 : nothing

def from_method(k)
  [pick(k), 1]
end
p from_method(true)
p from_method(false)

# an instance variable
class Holder
  def initialize(k)
    @v = k ? 1.5 : nothing
  end

  def v = @v
end
p [Holder.new(true).v, 1]
p [Holder.new(false).v, 1]

# a builtin that answers nil
def from_puts(k)
  r = k ? 1.5 : puts("side")
  [r, 1]
end
p from_puts(true)
p from_puts(false)

# arithmetic on it raises, as on nil
def added(k)
  r = k ? 1.5 : nothing
  r + 1.0
end
p added(true)
begin
  p added(false)
rescue NoMethodError
  puts "NoMethodError"
end

# as an argument
def passed(k)
  r = k ? 1.5 : nothing
  show(r)
end
puts passed(true)
puts passed(false)

# under a rescue modifier, and in a begin block
def modifier(stop)
  r = nothing(stop) rescue 1.5
  [r, 1]
end
p modifier(false)
p modifier(true)

def in_begin(stop)
  r = begin
    nothing(stop)
  rescue
    1.5
  end
  [r, 1]
end
p in_begin(false)
p in_begin(true)

# an Integer stored in a Hash
def integer_in_hash(k)
  r = k ? 7 : nothing
  h = { a: r }
  h[:a].nil?
end
p integer_in_hash(true)
p integer_in_hash(false)
