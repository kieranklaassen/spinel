# `r = obj.buf << x` keeps in r the String the reader hands out: a later
# `r << y` reaches obj.buf, and r.equal?(obj.buf). The pass that marks the
# chain's appends kept them in an array of 16. A chain of 17 links was left
# unmarked whole: r took a copy, and obj.buf kept the first link only, so
# twenty appends through a reader left it one character longer.

class Box
  attr_reader :b
  attr_accessor :c
  def initialize
    @b = +"b"
    @c = +"c"
  end

  def d = @b

  # the reader called on self
  def own
    t = b << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" \
        << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" \
        << "a" << "a" << "a" << "a"
    t << "!"
    [@b.size, t.size, t.equal?(@b)]
  end
end

class Outer
  attr_reader :box
  def initialize(box) = @box = box
end

# 20 links, kept and read
k = Box.new
t = k.b << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" \
    << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" \
    << "a" << "a" << "a" << "a"
p k.b.size, t.size, t.equal?(k.b)

# an append through the kept local reaches the reader's String
t << "!"
p k.b.size, t.size

# a second name for it
u = t
u << "?"
p k.b.size, t.size, u.size

# through attr_accessor, and through a reader written out
k = Box.new
t = k.c << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" \
    << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" \
    << "a" << "a" << "a" << "a"
t << "!"
p k.c.size, t.size
t = k.d << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" \
    << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" \
    << "a" << "a" << "a" << "a"
t << "!"
p k.b.size, t.size

# the reader called on self
p Box.new.own

# a reader of a reader
o = Outer.new(Box.new)
t = o.box.b << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" \
    << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" \
    << "a" << "a" << "a" << "a"
t << "!"
p o.box.b.size, t.size

# in a method, the kept local its value
def fill(k)
  t = k.b << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" \
      << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" \
      << "a" << "a" << "a" << "a"
  t << "!"
  t
end
k = Box.new
r = fill(k)
p k.b.size, r.size

# a concat link, then Integer and interpolated ones
k = Box.new
n = 7
t = k.b.concat("c") << 65 << 65 << 65 << 65 << 65 << 65 << 65 << 65 \
    << 65 << 65 << "#{n}" << "#{n}" << "#{n}" << "#{n}" << "#{n}" \
    << "#{n}" << "#{n}" << "#{n}" << "#{n}"
t << "!"
p k.b, t.equal?(k.b)

# 100 links
k = Box.new
t = k.b << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" \
    << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" \
    << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" \
    << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" \
    << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" \
    << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" \
    << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" \
    << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" \
    << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" \
    << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" \
    << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" \
    << "a" << "a" << "a" << "a" << "a" << "a" << "a" << "a" \
    << "a" << "a" << "a" << "a"
t << "!"
p k.b.size, t.size, t.equal?(k.b)
