# A Struct or Data member whose String the program changes in place through
# the member's reader (`c.x << "z"`, `c.x.upcase!`) is built from a String of
# its own, or from one the caller holds as the same object.

S = Struct.new(:x)
c = S.new("q".dup)
c.x << "z"
p c.x

Pair = Struct.new(:a, :b)
pr = Pair.new(+"q", +"r")
pr.a << "z"
pr.b.upcase!
p pr.to_a

# a local that names the member's String
t = pr.a
t << "!"
p pr.a, t.equal?(pr.a)

Kw = Struct.new(:name, :n, keyword_init: true)
k = Kw.new(n: 1, name: String.new("k"))
k.name << "w"
p k.name, k.n

D = Data.define(:x)
d = D.new("d#{1 + 1}")
d.x << "z"
p d.x
e = D[x: 12.to_s]
e.x.concat("!")
p e.x

# Data#with stores a new member the same way
w = d.with(x: +"w")
w.x << "z"
p w.x, d.x

# a String the caller already shares goes in as that String
s = +"s"
u = s
u << "a"
h = S.new(s)
h.x << "z"
p h.x, s, u, h.x.equal?(s)

# a frozen literal stays frozen in the member
f = S.new("lit")
begin
  f.x << "z"
rescue FrozenError => er
  puts er.class
end
p f.x

# nil beside a String
n = S.new(nil)
p n.x
p S.new.x

# a class value, a method, a block
kl = S
m = kl.new(:sym.to_s)
m.x << "z"
p m.x

def build(i) = S.new("b" * i)
b = build(2)
b.x << "z"
p b.x

all = [1, 2].map { |i| S.new(i.to_s) }
all.each { |o| o.x << "z" }
p all.map(&:x)

# an initialize of the program's own hands its String on with `super`
class Tag < Struct.new(:text)
  def initialize(t) = super(t + ">")
end
tg = Tag.new("<a")
tg.text << "!"
p tg.text

Pt = Data.define(:label) do
  def initialize(label:)
    super(label: label.dup)
  end
end
pt = Pt.new(label: "p")
pt.label << "t"
p pt.label

# two members made in one `super`, and two in one `with`
class Span < Struct.new(:from, :to)
  def initialize(a, b) = super(a + "<", b + ">")
end
sp = Span.new("a", "b")
sp.from << "!"
sp.to << "?"
p sp.to_a

Two = Data.define(:x, :y)
tw = Two.new(+"x", +"y").with(x: "c".dup, y: "d" + "e")
tw.x << "1"
tw.y << "2"
p tw.x, tw.y
