# A local assigned a boxed value under its `is_a?(String)` guard is another
# name for that String, as it is under `when String`: what is changed in
# place through the local is changed in the value's holder.
r = [+"ab", 5]
e = r[0]
if e.is_a?(String)
  t = e
  t << "z"
end
p r

# in a block, by kind_of?, and past a guard that leaves
a = [+"ab", 5, +"cd"]
a.each do |x|
  if x.kind_of?(String)
    k = x
    k << "!"
    puts k.size
  end
end
a.each do |x|
  next unless x.is_a?(String)
  n = x
  n.upcase!
end
p a

# an elsif arm, and the other mutators
b = [1, +"ab", 2.5]
b.each do |x|
  if x.is_a?(Integer)
    puts x + 1
  elsif x.is_a?(String)
    m = x
    m.concat("c")
    m.replace(m + m)
  end
end
p b

# two names
c = [+"ab", :s]
c.each do |x|
  if x.is_a?(String)
    f = u = x
    f << "1"
    v = x
    w = v
    w << "2"
    puts u, v
  end
end
p c

# handed to a method that appends to its parameter
def bang(q) = q << "!"
z = [+"ab", 5]
z.each do |x|
  if x.is_a?(String)
    j = x
    bang(j)
  end
end
p z

# a method's boxed parameter
def mark(v)
  return unless v.is_a?(String)
  g = v
  g << "?"
  nil
end
s = +"ab"
mark(s)
mark(7)
p s

# a local that is only read keeps the narrowed String
d = [+"ab", 5]
d.each do |x|
  if x.is_a?(String)
    h = x
    puts h.center(6, "*"), h.tr("a", "b")
  end
end
p d
