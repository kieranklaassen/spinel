# A block that holds a `next` and answers a Float keeps the Float at the
# yield. The yield read the block's value from a slot declared sp_int, while
# the `next` and the block's last expression both stored a Float in it, so
# 2.5 came back 2.0, and a bare `next` came back a huge negative Float in
# place of nil.
def twice
  r = []
  r << (yield 1)
  r << (yield 2)
  r
end
p twice { |x| next 1.5 if x == 2; 2.5 }

# a bare `next` and a `next nil` answer nil
p twice { |x| next if x == 2; 2.5 }
p twice { |x| next nil if x == 2; 2.5 }

# the Float does not have to be a literal
p twice { |x| next x / 4.0 if x == 2; x + 0.25 }
p twice { |x| next 0.5 if x == 2; x > 5 ? 9.5 : 3.5 }
p twice { |x| next 0.5 if x == 2; if x > 5 then 9.5 else 3.5 end }

# a block whose last expression is nil beside a Float `next`, and -0.0
p twice { |x| next 0.25 if x == 2; nil }
p twice { |x| next -0.0 if x == 2; x / 4.0 }

# the method reads the value into a local, an operand, a condition, a String
def total
  s = 0.0
  s += yield 1
  s += yield 2
  s
end
p total { |x| next 1.5 if x == 2; 2.25 }

def first_big
  v = yield 1
  return v if v > 2.0
  yield 2
end
p first_big { |x| next 0.5 if x == 2; 1.5 }
p first_big { |x| next 0.5 if x == 2; 2.5 }

def line
  "#{yield 1} and #{yield 2}"
end
puts line { |x| next 1.5 if x == 2; 2.5 }

# the call inside a loop, its value added up
i = 0
t = 0.0
while i < 4
  i += 1
  t += total { |x| next 0.25 if i.even?; x * 0.5 }
end
p t

# through super, through a block parameter, and through a second yield
class Pair
  def read
    [yield(1), yield(2)]
  end
end

class Wide < Pair
  def read
    a = super() { |x| next 1.5 if x == 2; 2.5 }
    a
  end
end
p Wide.new.read

def run(&b)
  [b.call(1), b.call(2)]
end
p run { |x| next 1.5 if x == 2; 2.5 }

def inner
  [yield(1), yield(2)]
end

def outer
  inner { |v| yield v }
end
p outer { |x| next 1.5 if x == 2; 2.5 }

# inside a Fiber's body
f = Fiber.new { a = twice { |x| next 1.5 if x == 2; 2.5 }; a }
p f.resume

# where the method keeps the value boxed, the nil of a bare `next` is nil
# as well: it was boxed as a Float
p twice { |x| next if x == 2; x + 0.5 }

def kept
  v = yield 2
  v.nil? ? "none" : v.to_s
end
puts kept { |x| next if x == 2; x + 0.5 }
puts kept { |x| next "s" if x == 9; "t" }

def both
  [yield(1), yield(2)]
end
p both { |x| next if x == 2; 2.5 }
p both { |x| next if x == 2; 7 }

class Sum
  def add
    s = 0.0
    v = yield 1
    s += v unless v.nil?
    v = yield 2
    s += v unless v.nil?
    s
  end
end

class Half < Sum
  def add
    a = super() { |x| next nil if x == 2; x + 0.5 }
    a
  end
end
p Half.new.add

# these were right and stay right: a Float with no fraction, a block with
# no `next`, an Integer, and a yield whose value is not read
p twice { |x| next 1.0 if x == 2; 2.0 }
p twice { |x| x == 2 ? 1.5 : 2.5 }

def again
  [yield(1), yield(2)]
end
p again { |x| next if x == 2; 7 }

def count
  n = 0
  yield 1
  n += 1
  yield 2
  n + 1
end
p count { |x| next 1.5 if x == 2; 2.5 }
