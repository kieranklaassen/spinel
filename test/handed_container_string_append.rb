# A String a method stores into the Array or Hash it was handed is an element
# of the caller's container, and a change made through the container is a
# change to that String. The caller's own elements were shared handles and
# the method's a plain copy beside them, so the change was lost.

def hc_shl(q, v); q << v; end
a1 = [+"a"]
hc_shl(a1, +"s")
a1[1] << "y" * 40
p a1

def hc_push(q, v); q.push(v); end
a2 = [+"a"]
hc_push(a2, +"s")
a2[1] << "y"
p a2

def hc_append(q, v); q.append(v); end
a3 = [+"a"]
hc_append(a3, +"s")
a3.last << "y"
p a3

def hc_unshift(q, v); q.unshift(v); end
a4 = [+"a"]
hc_unshift(a4, +"s")
a4[0] << "y"
p a4

def hc_index(q, v); q[0] = v; end
a5 = [+"a"]
hc_index(a5, +"s")
a5[0] << "y"
p a5

def hc_two(q, v, w); q << v; q << w; end
a6 = [+"a"]
hc_two(a6, +"s", +"t")
a6[1] << "y"
a6[2] << "z"
p a6

# a Hash, by a Symbol and by a String key
def hc_sym(h, v); h[:k] = v; end
h1 = {a: +"a"}
hc_sym(h1, +"s")
h1[:k] << "y" * 40
p h1.to_a

def hc_str(h, v); h["k"] = v; end
h2 = {"a" => +"a"}
hc_str(h2, +"s")
h2["k"] << "y"
p h2.to_a

def hc_store(h, k, v); h.store(k, v); end
h3 = {a: +"a"}
hc_store(h3, :k, +"s")
h3[:k] << "y"
p h3.to_a

# other changes than an append
def hc_put(q, v); q << v; end
c1 = [+"a"]
hc_put(c1, +"s")
c1[1].replace("r" * 40)
p c1
c2 = [+"a"]
hc_put(c2, +"s")
c2[1].insert(0, "i" * 40)
p c2
c3 = [+"a"]
hc_put(c3, +"s")
c3[1].upcase!
p c3
c4 = [+"a"]
hc_put(c4, +"s")
e4 = c4[1]
e4 << "y" * 40
p c4, e4.equal?(c4[1])
c5 = [+"a"]
hc_put(c5, +"s")
c5.each { |e| e << "!" }
p c5

# the String is the caller's own variable too
s1 = +"s"
d1 = [+"a"]
hc_put(d1, s1)
d1[1] << "y" * 40
s1 << "z"
p d1, s1, s1.equal?(d1[1])

# the method answers the String it stored
def hc_answer(q, v); q << v; v; end
d2 = [+"a"]
r2 = hc_answer(d2, +"s")
r2 << "z" * 40
d2[1] << "y"
p d2, r2.equal?(d2[1])

# one method, three callers: a literal, a method's result, a variable
def hc_bang(v); v + "!"; end
k1 = ["x"]
hc_put(k1, "y")
p k1
k2 = [+"w"]
hc_put(k2, hc_bang("k"))
k2[1] << "y"
p k2
x3 = +"x"
k3 = [+"w"]
hc_put(k3, x3)
x3 << "more"
p k3

# two calls deep, and a method that hands its parameter on
def hc_inner(q, v); q << v; end
def hc_outer(q, v); hc_inner(q, v); end
t1 = [+"a"]
hc_outer(t1, +"s")
t1[1] << "y" * 40
p t1

def hc_walk(acc, n)
  acc << "n#{n}"
  return if n <= 0
  hc_walk(acc, n - 1)
  hc_walk(acc, n - 2) if n > 2
  hc_walk(acc, n - 3) if n > 4
end
t2 = [+"a"]
hc_walk(t2, 6)
t2[1] << "y"
p t2.size, t2[1]

# a class's method and a class method
class HcFiller
  def put(q, v); q << v; end
  def self.put(q, v); q << v; end
end
m1 = [+"a"]
HcFiller.new.put(m1, +"s")
m1[1] << "y" * 40
p m1
m2 = [+"a"]
HcFiller.put(m2, +"s")
m2[1] << "y"
p m2

# the caller is a method, and a block
def hc_caller
  q = [+"a"]
  hc_put(q, +"s")
  q[1] << "y" * 40
  q
end
p hc_caller
b1 = [+"a"]
1.times { hc_put(b1, +"s") }
b1[1] << "y"
p b1
[1].each do |i|
  b2 = [+"a"]
  hc_put(b2, +"s")
  b2[1] << "y" * 40
  p b2
end

# filled in a loop, changed by each
l1 = [+"a"]
3.times { |i| hc_put(l1, "n#{i}") }
l1.each { |e| e << "y" }
p l1

# an Integer beside the Strings
i1 = [+"a", 1]
hc_put(i1, +"s")
i1[2] << "y"
p i1

# a frozen literal stays frozen
def hc_lit(q); q << "lit"; end
f1 = [+"a"]
hc_lit(f1)
begin
  f1[1] << "y"
rescue FrozenError => e
  p e.class
end
p f1

# the method stores one of the container's own elements again
def hc_again(h); h[:x] = h[:j]; end
g1 = {j: +"a"}
hc_again(g1)
g1[:x] << "y" * 40
p g1.to_a

# the element read into a boxed local, a second name for it, and a method
# and an instance variable it is handed to
def hc_poke(e); e << "y" * 40; end
p1 = [+"a", 1]
hc_put(p1, +"s")
px = p1[2]
px << "y" * 40
p p1
p2 = [+"a", 1]
hc_put(p2, +"s")
hc_put(p2, +"t")
py = p2[2]
pz = py
pz << "y" * 40
pw = p2[3]
pw << "!"
p p2
p3 = [+"a", 1]
hc_put(p3, +"s")
pv = p3[2]
hc_poke(pv)
p p3
class HcKeeper
  def put(q, v); q << v; end
  def run
    l = [+"a", 1]
    put(l, +"s")
    @x = l[2]
    @x << "y" * 40
    k = l[2]
    k << "!"
    l
  end
end
p HcKeeper.new.run
