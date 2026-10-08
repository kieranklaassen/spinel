# A begin block that ends in a write of a local: the block answers the
# String the local holds, to whatever takes its value.

s = +"a"
v = begin
  t = s << "g"
end
v << "!"
p v, s, t
p v.equal?(s)

# the write under a rescue, and in a rescue's own body
u = +"u"
w = begin
  raise "x" if u.empty?
  k = u
rescue
  k = u
end
w << "?"
p w, u, k

r = +"r"
x = begin
  raise "boom"
rescue
  y = r << "1"
end
x << "2"
p x, r, y

# an ensure changes the String after the block's value is taken
e = +"e"
z = begin
  q = e
ensure
  e << "n"
end
z << "d"
p z, e, q

# `&&=` and `||=`
a2 = +"k"
b2 = a2
c2 = begin
  b2 &&= a2
end
c2 << "2"
p c2, a2, b2

d2 = nil
e2 = begin
  d2 ||= a2
end
e2 << "3"
p e2, a2, d2

# the value only read
p(begin; t1 = s; end)
puts(begin; t2 = s.concat("#"); end)
p((begin; t3 = s; end).size)
p [begin; t4 = s; end, 1]
p "#{begin; t5 = s; end}."
p(begin; t6 = s; end || "z")

# the value changed in place
(begin; t7 = s; end) << "<"
(begin; t8 = s; end).upcase!
p s

arr = []
arr << begin; t9 = s; end
arr[0] << "~"
p s, arr

@i = begin; ta = s; end
@i << "i"
p s, @i

$g = begin; tb = s; end
$g << "g"
p s, $g

def add(x) = x << "+"
add(begin; tc = s; end)
p s

# in a method
def run
  s = +"m"
  v = begin
    t = s.replace("n")
  end
  v << "o"
  [v, s, t]
end
p run
