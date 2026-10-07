# `c && yield` and `c || yield` where the blocks differ by call site: the
# chain's value is boxed for the sites together, and a site whose block
# answers true or false handed its flat C `&&` on unboxed, which did not
# build.
def show(x)
  x
end

def kept(c)
  x = (c && yield)
  x
end
p kept(true) { true }
p kept(true) { 9 }
p kept(false) { 9 }

def either(c)
  x = (c || yield)
  x
end
p either(false) { false }
p either(false) { "s" }
p either(true) { "s" }

# as an argument and as an element
def shown(c)
  show(c && yield)
end
p shown(true) { false }
p shown(true) { :s }
p shown(false) { :s }

def listed(c)
  [(yield && c)]
end
p listed(true) { true }
p listed(true) { 2.5 }
p listed(false) { 2.5 }

# three in a row, a negated side, and the keyword forms
def chained(c, d)
  x = (c && d && yield)
  x
end
p chained(true, true) { true }
p chained(true, true) { [1] }
p chained(true, false) { [1] }

def negated(c)
  x = (!c && yield)
  x
end
p negated(false) { true }
p negated(false) { nil }

def worded(c)
  x = (c and yield)
  y = (c or yield)
  [x, y]
end
p worded(true) { false }
p worded(false) { 9 }

# into an instance variable
class Box
  def fill(c)
    @v = (c && yield)
    @v
  end
end
p Box.new.fill(true) { true }
p Box.new.fill(true) { "s" }
