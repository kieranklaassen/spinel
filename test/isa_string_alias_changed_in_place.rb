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
    k << "!" << "?"
    puts k.size, k
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
    m.prepend("<")
    m.sub!("b", "bb")
    m[0] = "{"
  end
end
p b

# two locals assigned the one element
c = [+"ab", :s]
c.each do |x|
  if x.is_a?(String)
    f = x
    f << "1"
    v = x
    v << "2"
    puts f, v
  end
end
p c

# an Array born empty and filled by index keeps the handle of a String
# its iterator's element is changed through: the read stays boxed there
def filled
  n = 1
  r = []
  r[0] = "a#{n}"
  r[1] = 5
  r.each { |e| if e.is_a?(String); fl = e; fl << "z"; end }
  p r
  r.size
end
filled

# Everything below keeps the narrowed String, as it did.

# a local that is only read
d = [+"ab", 5]
d.each do |x|
  if x.is_a?(String)
    h = x
    puts h.center(6, "*"), h.tr("a", "b")
  end
end
p d

# a name that is the receiver of a call with a block: the program reads
# it under that name
y = [+"ab", 5]
o = y[0]
if o.is_a?(String)
  l = o
  l.concat("z")
  l.each_char { |ch| print ch, "." }
  puts
end

# a name that is another call's operand, a Range's end or a second name:
# a box does not answer there as a String does
w = [+"aa bb ", 5]
we = w[0]
if we.is_a?(String)
  wt = we
  wt << "z"
  p ("a".."b").cover?(wt), "AA BB Z".casecmp?(wt), ("a"..wt).cover?("aa")
  wu = wt
  p wu.size
end

# a name assigned what a method returned and read nowhere else
def pick(i) = i.odd? ? "s#{i}" : i
3.times do |i|
  got = pick(i)
  if got.is_a?(String)
    own = got
    own << "z"
    puts own
  end
end

# an Array a call answers has a second name, and a plain String may be put
# in it under that one; so may a `fetch`'s default be one. An append that
# fits in the String's spare room is seen through the Array, as it was
g = [+"ab", 5]
gq = g.each { |x| x }
gq << "CD".downcase
ge = g[2]
if ge.is_a?(String)
  gt = ge
  gt << "z"
end
p g
dflt = "CD".downcase
fe = g.fetch(7, dflt)
if fe.is_a?(String)
  ft = fe
  ft << "y"
end
p dflt

# an Array born empty, filled by index and read by index keeps a plain
# String, and so does a Hash filled by key
def filled_read
  n = 1
  r = []
  r[0] = "a#{n}"
  r[1] = 5
  e = r[0]
  if e.is_a?(String)
    fr = e
    fr << "z"
  end
  p r
end
filled_read
i = 1
kv = {}
kv[:a] = "a#{i}"
kv[:b] = 5
kv.each_value { |ev| if ev.is_a?(String); kt = ev; kt << "z"; end }
p kv.values
