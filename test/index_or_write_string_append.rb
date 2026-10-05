# `c[k] ||= v` stores v as `c[k] = v` does: a String it leaves in a Hash or
# an Array is the one a later `c[k] << x` appends to.

# gathering Strings by key
h = {}
["a", "b", "a"].each do |w|
  h[w] ||= +""
  h[w] << "!"
end
p h.to_a

# beside Strings the Hash holds already; a key that is there stores nothing
g = {a: +"x"}
g[:k] ||= +""
g[:k] << "v"
g[:a] ||= +"n"
g[:a] << "w"
p g.to_a

# an Array slot
a = [nil, +"x"]
a[0] ||= +""
a[0] << "v"
p a

# a Hash an instance variable holds
class Index
  def initialize; @h = {}; end
  def add(k, x)
    @h[k] ||= +""
    @h[k] << x
  end
  def to_a = @h.to_a
end
i = Index.new
i.add("a", "1"); i.add("b", "2"); i.add("a", "3")
p i.to_a

# a Hash a parameter holds
def gather(c, k, x)
  c[k] ||= +""
  c[k] << x
end
q = {}
gather(q, :a, "1"); gather(q, :a, "2")
p q.to_a

# a local stored by `||=` is the element: a change through either name
# shows through both
s = +"s"
m = {}
m[:k] ||= s
s << "1"
m[:k] << "2"
p m.to_a, s, s.equal?(m[:k])

# `&&=` stores the same way
n = {k: +"old"}
n[:k] &&= +"new"
n[:k] << "!"
t = +"t"
n[:k] &&= t
t << "?"
p n.to_a, t.equal?(n[:k])

# other in-place methods reach it too
u = {}
u[:k] ||= +"abc"
u[:k].upcase!
u[:k].concat("d", "e")
p u.to_a

# a key the write did not store is still nil, bound to a local too
w = {}
w[:k] &&= +""
w[:j] ||= +""
z = w[:k]
p z
begin
  z << "3"
rescue NoMethodError
  puts "nil takes no append"
end
p w.to_a
