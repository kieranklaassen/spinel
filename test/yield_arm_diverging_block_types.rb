# A method whose value is a `yield` beside another arm (a rescue modifier,
# an if or a ternary, `||`, a `case`), called with blocks that answer
# different types: each call answers its own block's value. The arm and
# the first site's block settled the method's return, and a later site's
# value was converted to it: `guarded { 9 }` below answered :"" for 9.
def guarded
  yield rescue :rescued
end
p guarded { :s }
p guarded { 9 }
p guarded { raise "no" }

def chosen(c)
  if c
    yield
  else
    :none
  end
end
p chosen(true) { :s }
p chosen(true) { 9 }
p chosen(false) { 0 }

def either(c)
  c ? yield : 7
end
p either(true) { 9 }
p either(true) { "s" }
p either(false) { 0 }

def fallback
  yield || "none"
end
p fallback { "s" }
p fallback { 9 }
p fallback { nil }

def picked(c)
  case c
  when 1 then yield
  when 2 then 1.5
  else :none
  end
end
p picked(1) { 2.5 }
p picked(1) { 9 }
p picked(2) { 0 }
p picked(3) { 0 }

# the same arms on the way into a local, and in an instance method
def kept
  v = (yield rescue :rescued)
  v
end
p kept { :s }
p kept { 9 }

class Box
  def initialize(on)
    @on = on
  end

  def get
    @on ? yield : :off
  end
end
p Box.new(true).get { :s }
p Box.new(true).get { [1, 2] }
p Box.new(false).get { 0 }

# blocks that answer one type keep it
def same(c)
  c ? yield : 0
end
a = same(true) { 4 }
b = same(true) { 5 }
p a + b
