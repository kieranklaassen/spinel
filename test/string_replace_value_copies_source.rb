# String#replace whose value is taken gives the receiver a copy of the
# source's bytes, as the statement form does. Rebound to the source itself,
# a receiver replaced from a literal was left frozen and its next change
# raised FrozenError; replaced from a String that can change, it was that
# String, and a change of either showed in both.
def reset(s)
  s.replace("r2")
end

u = +"abc"
reset(u)
u << "x"
p u

a = +"abc"
p(a.replace("w"))
a << "x"
p a

b = +"abc"
p b.replace("").size
b << "x"
p b

# a literal a variable holds, and the value is the receiver itself
lit = "lv"
c = +"abc"
p c.replace(lit).equal?(c)
c << "x"
p c
p lit

$g = +"abc"
p($g.replace("w"))
$g << "x"
p $g

class Holder
  def initialize
    @s = +"abc"
  end

  def swap
    @s.replace("w")
  end

  def add
    @s << "x"
  end
end
h = Holder.new
p h.swap
p h.add

d = +"abc"
p([1].map { d.replace("w") })
d << "x"
p d

e = +"abc"
p e.replace(e)
e << "x"
p e

# a source that can change is copied too: two Strings afterwards, and a
# change of one is not seen through the other
v = +"mv"
v << "1"
w = +"abc"
p w.replace(v).equal?(v)
w << "x"
p v
p w
v << "2"
p w

# a frozen receiver still raises
f = "abc"
begin
  p f.replace("w")
rescue FrozenError => err
  puts err.message
end
p f
