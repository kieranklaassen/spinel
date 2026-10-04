# A container that stores one of its own elements under another key or index
# holds one String twice, and an append through either reaches both. Demanding
# the container's Strings as shared handles met the element among the stores
# and came back for the same container, and the compiler did not end.

h = {j: +"j"}
h[:k] = h[:j]
h[:k] << "v"
p h.to_a, h[:k].equal?(h[:j])

# six times over
m = {a: +"a"}
m[:b] = m[:a]
m[:c] = m[:b]
m[:d] = m[:c]
m[:e] = m[:d]
m[:f] = m[:e]
m[:f] << "!"
p m.to_a

# an Array, by push and by index
a = [+"a", 1]
a << a[0]
a[2] << "!"
p a
b = [nil, +"j"]
b[0] = b[1]
b[0] << "v"
p b, b[0].equal?(b[1])
c = [+"c", 1]
c[1] = c.first
c[1] << "!"
p c

# through fetch, and with a fallback beside the element
f = {j: +"j"}
f[:k] = f.fetch(:j)
f[:k] << "v"
p f.to_a
o = {}
o[:k] = o[:k] || +""
o[:k] << "v"
o[:k] = o[:k] || +""
o[:k] << "w"
p o.to_a

# a Hash held in an instance variable
class Table
  def initialize; @h = {j: +"j"}; end
  def copy(k)
    @h[k] = @h[:j]
    @h[k] << k.to_s
  end
  def to_a = @h.to_a
end
t = Table.new
t.copy(:a)
t.copy(:b)
p t.to_a

# a Hash that is a parameter
def twice(h)
  h[:k] = h[:j]
  h[:k] << "v"
end
q = {j: +"j"}
twice(q)
p q.to_a

# two Hashes that store each other's, and three in a ring
g = {x: +"g"}
r = {}
r[:k] = g[:x]
g[:y] = r[:k]
r[:k] << "!"
p g.to_a, r.to_a
x = {s: +"x"}
y = {s: +"y"}
z = {s: +"z"}
x[:t] = y[:s]
y[:t] = z[:s]
z[:t] = x[:s]
x[:t] << "1"
y[:t] << "2"
z[:t] << "3"
p x.to_a, y.to_a, z.to_a
