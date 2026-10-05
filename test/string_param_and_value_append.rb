# A method's String parameter taken through `&&` is the caller's String:
# `t = k >= 0 && s` names it, so a change through `t` reaches the caller,
# as it does through `t = s` and `t = k >= 0 ? s : r`.
def tag(k, s)
  t = k >= 0 && s
  t << "x" if t
  t
end
a = +"a"
r = tag(1, a)
p a
p r
r = tag(-1, a)
p a
p r

def pick(k, s1, s0)
  t = (k >= 0 && s1) || s0
  t << "y"
  [t.equal?(s1), t.equal?(s0)]
end
b = +"b"
c = +"c"
p pick(1, b, c)
p b, c
p pick(-1, b, c)
p b, c

# every in-place method, not only `<<`
def edit(k, s1, s0)
  t = (k >= 0 and s1) || s0
  t.concat("z")
  t.insert(0, "<")
  t.upcase!
  t.replace("R") if k > 5
  nil
end
edit(0, b, c)
p b, c
edit(9, b, c)
p b, c

# the value may be false, an Integer or the String
def mark(k, s)
  t = k > 0 ? s : k
  t << "m" if t.is_a?(String)
  u = k > 1 && k < 9 && s
  u << "n" if u
  [t.class, u.class]
end
d = +"d"
p mark(0, d)
p d
p mark(1, d)
p d
p mark(2, d)
p d

class Stamper
  def initialize(sep) = @sep = sep
  def stamp(k, s:, t: +"t")
    v = k >= 0 && s
    v << @sep if v
    w = k < 0 && t
    w << @sep if w
    [s, t]
  end
  def self.twice(k, s)
    2.times do
      t = k >= 0 && s
      t << "w" if t
    end
    nil
  end
end
e = +"e"
p Stamper.new("-").stamp(1, s: e)
p e
p Stamper.new("+").stamp(-1, s: e)
p e
Stamper.twice(1, e)
p e

# what the caller hands over: an instance variable, an Array's element, a
# parameter of its own, a fresh String and a frozen literal
class Holder
  attr_reader :name, :list
  def initialize
    @name = +"n"
    @list = [+"l0", +"l1"]
  end
  def run
    suffix(1, @name)
    suffix(-1, @name)
    last(1, @list[1])
    last(-1, @list[0])
    self
  end
  def suffix(k, s)
    t = k >= 0 && s
    t << "x" if t
  end
  def last(k, s)
    t = k >= 0 && s
    t.concat("y") if t
  end
end
h = Holder.new.run
p h.name, h.list
def outer(k, s) = tag(k, s)
f = +"f"
outer(1, f)
outer(-1, f)
p f
p tag(1, +"g")
begin
  tag(1, "lit")
rescue FrozenError => err
  p err.class
end

# kept in an instance variable: through `&&`, and whole
class Keep
  def take(k, s) = (@v = k >= 0 && s)
  def whole(s) = (@w = s)
  def mark
    @v << "v" if @v
    @w << "w"
    nil
  end
end
kp = Keep.new
i = +"i"
j = +"j"
kp.take(1, i)
kp.whole(j)
kp.mark
p i, j
