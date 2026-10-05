# The value of `c[k] ||= v` is the element the write leaves in the slot: an
# append to it reaches the String the Hash or the Array holds.

# gathering Strings by key
h = {}
["a", "b", "a"].each { |w| (h[w] ||= +"") << "!" }
p h.to_a

# an Array slot
a = []
(a[0] ||= +"") << "1"
(a[0] ||= +"") << "2"
(a[1] ||= +"z") << "3"
p a

# a Hash an instance variable holds
class Index
  def initialize; @h = {}; end
  def add(k, x) = (@h[k] ||= +"") << x
  def to_a = @h.to_a
end
i = Index.new
i.add("a", "1"); i.add("b", "2"); i.add("a", "3")
p i.to_a

# a Hash a parameter holds, and one a lambda captures
def gather(c, k, x) = (c[k] ||= +"") << x
q = {}
gather(q, :a, "1"); gather(q, :a, "2")
add = ->(k, x) { (q[k] ||= +"") << x }
add.call(:b, "3"); add.call(:a, "4")
p q.to_a

# `&&=`
n = {k: +"old"}
(n[:k] &&= +"x") << "y"
p n.to_a

# other in-place methods on the value of the write
u = {}
(u[:k] ||= +"abc").upcase!
(u[:k] ||= +"").concat("d", "e")
(u[:k] ||= +"").prepend(">")
p u.to_a

# an Array as the value is appended to as before, beside a String the
# Hash holds
v = {s: +"str"}
(v[:a] ||= []) << 1
(v[:a] ||= []) << 2
v[:s] << "!"
p v.to_a

# the slot holds a String already: the append goes to it, whatever the
# right-hand side would have stored
w = {k: +"s"}
(w[:k] ||= []) << "x"
p w.to_a
