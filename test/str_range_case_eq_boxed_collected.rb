# spinel: gc-stress
# === of a String Range in a local with a boxed String that the
# argument's own call hands on after it has allocated. With
# --share-strings a Range a variable holds is read as a copy of each end
# before the argument is made, and nothing holds those copies while the
# call allocates: the String, plain or appended, is covered by the ends
# read again from the Strings the Range keeps.
def pick(h, key)
  x = []
  300.times { |i| x << ("s" + i.to_s) }
  h[key]
end

def plain(i)
  x = []
  300.times { |j| x << ("s" + j.to_s) }
  i > 1 ? "bb" : (i > 0 ? "ab" : 1)
end

a = "a".dup
a << "a"
z = "a".dup
z << "z"
h = {"in" => "a".dup, "out" => "b".dup, "n" => 1}
h["in"] << "b"
h["out"] << "b"
r = (a..z)

p r === pick(h, "in"), r === pick(h, "out"), r === pick(h, "n"), r === pick(h, "none")
p r === plain(1), r === plain(2), r === plain(0)

n = 0
m = 0
k = 0
l = 0
20.times do
  n += 1 if r === pick(h, "in")
  m += 1 if r === pick(h, "out")
  k += 1 if r === plain(1)
  l += 1 if r === plain(2)
end
p n, m, k, l
