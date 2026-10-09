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

# a local that is only read keeps the narrowed String
d = [+"ab", 5]
d.each do |x|
  if x.is_a?(String)
    h = x
    puts h.center(6, "*"), h.tr("a", "b")
  end
end
p d

# a name that is the receiver of a call with a block keeps the narrowed
# String: the program reads it under that name
y = [+"ab", 5]
o = y[0]
if o.is_a?(String)
  l = o
  l.concat("z")
  l.each_char { |ch| print ch, "." }
  puts
end

# so does a name assigned what a method returned and read nowhere else
def pick(i) = i.odd? ? "s#{i}" : i
3.times do |i|
  got = pick(i)
  if got.is_a?(String)
    own = got
    own << "z"
    puts own
  end
end

# an Array born empty and filled by index keeps the handle of a String
# its iterator's element is changed through: the read stays boxed there
def filled
  n = 1
  r = []
  r[0] = "a#{n}"
  r[1] = 5
  r.each { |e| if e.is_a?(String); fl = e; fl << "z"; end }
  p r
end
filled

# a holder that keeps a plain String hands out that String: the local
# keeps the narrowed read there, and an append that fits in the String's
# spare room is seen through the holder, as it was
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
