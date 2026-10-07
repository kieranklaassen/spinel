# Yielding methods that call each other, each handing on a block that yields.
# Whether a yield's Integer or Float value can be nil is asked of the blocks
# at the method's call sites, and such a block's value is the other method's
# yield: the two were asked about each other without end, and the compiler
# ran out of stack.
def ea(n)
  if n == 0
    yield 0
  else
    eb(n - 1) { |v| yield v + 1 }
  end
end
def eb(n)
  if n == 0
    yield 0
  else
    ea(n - 1) { |v| yield v + 1 }
  end
end
p ea(5) { |v| v * 2 }
p ea(0) { |v| v - 1 }
x = ea(4) { |v| v * 3 }
p x + 1

# a block that may answer nil
def na(n) = n == 0 ? yield(0) : nb(n - 1) { |v| yield v + 1 }
def nb(n) = n == 0 ? yield(0) : na(n - 1) { |v| yield v + 1 }
p na(5) { |v| v > 3 ? nil : v }
p na(2) { |v| v > 3 ? nil : v }
h = { k: na(6) { |v| v > 3 ? nil : v } }
p h[:k]

# Floats, and three methods round
def fa(n) = n == 0 ? yield(0.5) : fb(n - 1) { |v| yield v + 1.0 }
def fb(n) = n == 0 ? yield(0.5) : fc(n - 1) { |v| yield v + 1.0 }
def fc(n) = n == 0 ? yield(0.5) : fa(n - 1) { |v| yield v + 1.0 }
p fa(4) { |v| v * 2.0 }
p [fa(7) { |v| v }, fa(0) { |v| v }]

# the value kept in a local on the way up, and the block yielded on as it is
def ka(n)
  return yield(1) if n == 0
  r = kb(n - 1) { |v| yield v }
  r + 1
end
def kb(n)
  return yield(1) if n == 0
  r = ka(n - 1) { |v| yield v }
  r + 1
end
p ka(3) { |v| v * 10 }

# the same two methods in a class
class Walk
  def ea(n) = n == 0 ? yield(0) : eb(n - 1) { |v| yield v + 1 }
  def eb(n) = n == 0 ? yield(0) : ea(n - 1) { |v| yield v + 1 }
end
p Walk.new.ea(5) { |v| v * 2 }
