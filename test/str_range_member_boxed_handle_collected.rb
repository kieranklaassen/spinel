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
