# A Hash whose stores are out of the value block's sight keeps its behaviour
# where nothing is lost: a frozen literal raises FrozenError, an Array value
# is the same object, a block that only reads changes nothing.
def fill(h, k, v); h[k] = v; end
def bump(h); h.each_value { |x| x << "!" }; end
def build; h = {}; h[:a] = "lit"; h; end
def frozen
  yield
rescue FrozenError => e
  p e.class
end

h = {}
fill(h, :a, "lit")
frozen { h.each_value { |x| x << "!" } }
frozen { bump({k: "lit"}) }
g = build
frozen { g.each_pair { |k, x| x << "!" } }
p h.to_a, g.to_a

# The other Hash the same method fills holds a fresh String; this one does not.
other = {}
fill(other, :b, +"fresh")
p other.to_a

class Holder
  def initialize; @h = {}; end
  def add(v); @h[:a] = v; end
  def go; @h.each { |k, x| x << "!" }; end
  def values; @h.to_a; end
end
k = Holder.new
k.add("lit")
frozen { k.go }
p k.values

$far = {}
$far[:a] = "lit"
frozen { $far.values.each { |x| x << "!" } }
p $far.to_a

d = Hash.new { |hh, key| hh[key] = "lit" }
d[:a]
frozen { d.each_value { |x| x << "!" } }
t = %w[a b].to_h { |key| [key, "lit"] }
frozen { t.each_value { |x| x << "!" } }
p d.to_a, t.to_a

# Array values are shared, and a read is a read.
a = {}
fill(a, :a, [1])
a.each_value { |x| x << 2 }
p a.to_a
r = {}
fill(r, :a, +"q")
r.each_value { |x| p x + "!" }
r.each_pair { |key, x| x = +"local"; x << "!"; p x }
p r.to_a
