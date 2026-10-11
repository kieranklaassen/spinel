# spinel: gc-stress
# A String Range asked for a boxed appended String while the collector
# runs. In a local, the argument's own call hands the String on after it
# has allocated: with --share-strings a Range a variable holds is read as
# a copy of each end before the argument is made, and nothing holds those
# copies while the call allocates, so the handle is compared with the
# Strings the Range keeps, read again once the argument is there. In a
# constant, the Range is the only holder of its two ends.
def pick(h, key)
  x = []
  300.times { |i| x << ("s" + i.to_s) }
  h[key]
end

def ends(i)
  ("a" + "a" * i)..("a" + "z" * i)
end

a = "a".dup
a << "a"
z = "a".dup
z << "z"
h = {"in" => "a".dup, "out" => "b".dup, "n" => 1}
h["in"] << "b"
h["out"] << "b"
r = (a..z)

p r.cover?(pick(h, "in")), r.include?(pick(h, "in")), r.member?(pick(h, "in"))
p r.cover?(pick(h, "out")), r.include?(pick(h, "out")), r.member?(pick(h, "out"))
p r.cover?(pick(h, "n")), r.cover?(pick(h, "none"))

n = 0
m = 0
20.times do
  n += 1 if r.cover?(pick(h, "in"))
  m += 1 if r.cover?(pick(h, "out"))
end
p n, m

x = (a...z)
k = 0
20.times { k += 1 if x.include?(pick(h, "in")) }
p k

R = ends(1)
pick(h, "n")
p R.cover?(pick(h, "in")), R.include?(pick(h, "out")), R.member?(pick(h, "in"))
c = 0
d = 0
20.times do
  c += 1 if R.cover?(pick(h, "in"))
  d += 1 if R.include?(pick(h, "out"))
end
p c, d

# An argument read from a local runs nothing between the Range's read and
# the compare, so there the copies are compared as they are: the Range in a
# local with held ends, in a local and in a constant as the only holder of
# its ends, and written where it is asked from two locals or two plain
# literals, with allocation between the calls.
v = h["in"]
w = h["out"]
s = ends(1)
pick(h, "n")
p r.cover?(v), r.include?(v), r.member?(w), s.cover?(v), s.include?(w)
p R.cover?(v), R.include?(v), R.member?(w)
p ("aa".."az").cover?(v), (a..z).include?(v), (a...z).member?(w)
e = 0
f = 0
20.times do
  pick(h, "n")
  e += 1 if r.cover?(v) && s.include?(v) && R.member?(v)
  f += 1 if r.include?(w) || s.cover?(w) || R.cover?(w)
  e += 1 if (a..z).cover?(v) && ("aa".."az").include?(v)
end
p e, f
