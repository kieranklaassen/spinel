# A named capture and a pattern binding write a local. A local that a
# proc captures lives in a cell, and these wrote `lv_<name>` all the same,
# so the C did not compile ('lv_t' undeclared).

# in a method, the lambda returned
def mk(s)
  w = "none"
  /(?<w>z+)/ =~ s
  -> { w.to_s + "!" }
end
p mk("azzb").call, mk("abc").call

# a named capture, the lambda made before it
t = "q"
l = -> { t.inspect }
if /(?<t>z+)/ =~ "azzb"
  p t
end
p l.call

# no match leaves nil
u = "q"
m = -> { u.inspect }
/(?<u>z+)/ =~ "abc"
p m.call, u

# two groups, one of them captured by the lambda
y = nil
n = -> { y.to_s + "-" }
if /(?<y>\d+)-(?<mo>\d+)/ =~ "on 2026-10 ok"
  p y, mo, n.call
end

# two groups, both captured, the lambda building an Array of them
q = "x"
r = "y"
lq = -> { [q, r] }
/(?<q>z+)(?<r>k+)/ =~ "azzkkb"
p lq.call, q, r

# the match is made inside the lambda
v = "q"
k = -> { /(?<v>z+)/ =~ "azzzb"; v }
p k.call, v

# in a loop, read by a block
seen = []
g = nil
%w[azb azzb b azzzb].each do |s|
  /(?<g>z+)/ =~ s
  seen << g.to_s
end
p seen, g

# `in String => a`
a = nil
la = -> { a.inspect }
case "zz"
in String => a
  p a
end
p la.call

# `in Integer => b` with a guard
b = nil
lb = -> { b.inspect }
case 9
in Integer => b if b > 1
  p b
end
p lb.call

# a bare target
c = nil
lc = -> { c.inspect }
case 7
in c
  p c
end
p lc.call

# an Array pattern: a first element, a rest, a last element
d = nil
e = nil
f = nil
ld = -> { [d, e, f].inspect }
case [1, 2, 3, 4]
in [d, *e, f]
  p d, e, f
end
p ld.call

# a Hash pattern: a value
h = nil
lh = -> { h.inspect }
case { a: 1, b: 2 }
in { a: h }
  p h
end
p lh.call

# a find pattern: the element found, read by a block
case [1, 5, 2]
in [*, 5 => i, *]
  [1, 2].each { |x| puts "#{x} #{i}" }
end

# a nested pattern, the binding made inside a lambda
j = nil
lj = -> {
  case [3, "s"]
  in [Integer => j, String]
    true
  end
}
p lj.call, j

# a lambda that writes the target afterwards
o = nil
lo = -> { o = "set" }
case "zz"
in String => o
  p o
end
lo.call
p o
