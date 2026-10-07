# A String stored by index into an Array that began empty is the Array's
# element: a block that changes it in place changes the element, as it
# does one that was pushed.
r = []
r[0] = +"ab"
r.each { |e| e << "z" }
p r

# the same String under its own name
c = +"cd"
u = []
u[0] = c
u.each { |e| e.upcase! }
p u, c

# other iterators, and a method's own Array
def fill(n)
  a = []
  n.times { |i| a[i] = "s#{i}" }
  a.each_with_index { |e, i| e << i.to_s }
  a.map { |e| e << "!" }
  a
end
p fill(3)

# a hole and another kind of element beside the String
m = []
m[1] = "x".dup
m[2] = 5
m.each { |e| e << "y" if e.is_a?(String) }
p m

# map! still settles, and a block that only reads changes nothing
k = []
k[0] = +"q"
k.map! { |e| e << "r" }
k.each { |e| puts e.size }
p k
