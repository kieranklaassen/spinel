# `h[k] = h.fetch(k, v)` where k may be there stores back the element it
# read: the append through h[k] reaches the String the Hash holds. Only the
# statement whose first run has to miss is refused
# (test/reject/fetch_default_string_stored_back.rb).

# the literal holds the key
a = {k: +"a"}
a[:k] = a.fetch(:k, +"")
a[:k] << "v"
p a.to_a

# a block default, the key stored first
b = {}
b[:k] = +"b"
b[:k] = b.fetch(:k) { +"" }
b[:k] << "v"
p b.to_a

# a variable key the literal may hold
c = {x: +"c"}
[:x, :x].each do |k|
  c[k] = c.fetch(k, +"")
  c[k] << "v"
end
p c.to_a

# a parameter's Hash
def add(h, k, x)
  h[k] = h.fetch(k, +"")
  h[k] << x
end
d = {x: +"d"}
add(d, :x, "1")
add(d, :x, "2")
p d.to_a

# an instance variable's Hash, filled before the fetch
class Notes
  def initialize
    @h = {}
  end

  def put(k, s)
    @h[k] = s
  end

  def add(k, x)
    @h[k] = @h.fetch(k, +"")
    @h[k] << x
  end

  def to_a = @h.to_a
end
n = Notes.new
n.put(:x, +"n")
n.add(:x, "1")
n.add(:x, "2")
p n.to_a

# another key's element, a miss nothing appends to, a default that is no String
e = {j: +"e"}
e[:k] = e.fetch(:j, +"")
e[:k] << "v"
p e.to_a
f = {}
f[:k] = f.fetch(:k, +"")
p f.to_a
g = {}
g[:k] = g.fetch(:k, [])
g[:k] << "v"
p g.to_a

# the store the refusal names
i = {}
%w[a b a].each do |w|
  k = w.to_sym
  i[k] = +"" unless i.key?(k)
  i[k] << "!"
end
p i.to_a
