# A String that `h[k] ||= v` or `h[k] &&= v` stores into a Hash a local or
# an instance variable holds is the String `h[k] << x` then appends to, as
# with `h[k] = v`.
h = {}
%w[a b a].each { |w| h[w] ||= +""; h[w] << "!" }
p h.to_a

# the write as the receiver of the append
g = {}
%w[a b a].each { |w| (g[w] ||= +"") << w }
p g.to_a

# `&&=`
t = { k: +"a" }
t[:k] &&= +"b"
t[:k] << "!"
p t.to_a

# Symbol and Integer keys, concat, a bang
s = {}
s[:k] ||= "abc".dup
s[:k].concat("d")
s[:k].upcase!
p s.to_a
n = {}
n[3] ||= String.new("x")
n[3] << "y"
p n.to_a

# a Hash an instance variable holds
class Index
  def initialize
    @by = {}
  end

  def add(k, x)
    @by[k] ||= +""
    @by[k] << x
    self
  end

  def to_a = @by.to_a
end
p Index.new.add(:a, "1").add(:b, "2").add(:a, "3").to_a

# a String a local holds
v = +"l"
u = {}
u[:k] ||= v
u[:k] << "!"
p u.to_a

# the key holds a String already: nothing is stored
o = { "a" => +"old" }
o["a"] ||= +"new"
o["a"] << "!"
p o.to_a

# other values are stored as before
c = {}
%w[a b a].each { |w| c[w] ||= 0; c[w] += 1 }
p c.to_a
l = {}
%w[a b a].each_with_index { |w, i| (l[w] ||= []) << i }
p l.to_a
