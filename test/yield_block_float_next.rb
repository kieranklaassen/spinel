# A block a method yields to answers a Float through `next <v>` or through
# its last expression when it holds a `next`: the Float is not cut to a whole
# number, and a `next` with no value is nil.
def run(a)
  v = yield a
  v
end

p run(7) { |x| next 0.5 if x == 3; x * 1.5 }
p run(3) { |x| next 0.5 if x == 3; x * 1.5 }
p run(3) { |x| next if x == 3; x * 1.5 }
p run(3) { |x| next nil if x == 3; x * 1.5 }
p run(5) { |x| next nil if x == 3; x * 1.5 }
p run(3) { |x| next 0.25 if x == 3; nil }
p run(4) { |x| next 0.25 if x == 3; nil }

def add(a)
  yield(a) + 1.0
end

p add(3) { |x| next 0.5 if x == 3; x * 1.5 }
p add(4) { |x| next 0.5 if x == 3; x * 1.5 }

def both(a)
  r = []
  r << yield(a)
  r << yield(a + 1)
  r
end

p both(3) { |x| next 0.5 if x == 3; x * 1.5 }
p both(2) { |x| next -0.0 if x == 3; x / 4.0 }

class Scale
  def initialize(f); @f = f; end
  def apply(v) = yield(v * @f)
  def half(v) = apply(v) { |w| next 0.125 if w > 10.0; w / 2 }
end
s = Scale.new(1.5)
p s.half(3), s.half(8)

i = 0
t = 0.0
while i < 4
  i += 1
  t += run(i) { |x| next 0.25 if x.even?; x * 0.5 }
end
p t
