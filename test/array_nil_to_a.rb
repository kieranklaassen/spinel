# nil.to_a and Array(nil) are [], also where the nil is in an Array slot:
# a slice that starts past the end, or a local one arm leaves nil.
def ints(k) = [1, 2][k, 5]
def floats(k) = [1.5][k, 5]
def strs(k) = ["a"][k, 5]
def mixed(k) = [1, "a"][k, 5]

p ints(3).to_a, floats(3).to_a, strs(3).to_a, mixed(3).to_a
p Array(ints(3)), Array(floats(3)), Array(strs(3)), Array(mixed(3))

# the answer is an Array like any other
v = ints(3).to_a
p v, v.size, v.empty?
v << 7
p v
w = Array(strs(3))
w << "z"
p w, w.size

# through a local one arm leaves nil
def pick(n)
  x = nil
  x = [n] if n > 0
  x.to_a
end
p pick(0), pick(4)

# an Array answers itself, not a copy
a = [1, 2]
p a.to_a.equal?(a), Array(a).equal?(a)
q = [1, "a"]
p q.to_a.equal?(q), Array(q).equal?(q)
p ints(0).to_a, ints(2).to_a
