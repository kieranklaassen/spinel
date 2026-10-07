# A String fetched out of a boxed container and stored back into it is the
# String the container holds from then on: a change in place through the
# element reaches it.
h = {}
%w[a b a a].each do |w|
  fresh = !h.key?(w)
  h[w] = h.fetch(w, +"")
  h[w] << "," unless fresh
  h[w] << w
end
p h.to_a

a = [+"a"]
a[1] = a.fetch(1, +"")
a[1] << "v"
p a

# fetched again once it is there, changed by other methods, and read back
h["a"] = h.fetch("a", +"")
h["a"].concat("!")
h["b"].upcase!
h["b"].prepend("<")
w = h["a"]
p w, w.size, h.to_a

# an Integer key and a key in a variable
n = {}
k = 1
n[k] = n.fetch(k, +"x")
n[k].replace("r")
n[2] = n.fetch(2, +"")
n[2] << "s" << "t"
p n.to_a

# the block's default, inside a method
def fill
  b = [+"b"]
  b[1] = b.fetch(1) { +"" }
  b[1] << "x" << "y"
  b[1].upcase!
  b
end
p fill

# the element that is a String already keeps its own
g = { "k" => +"a" }
g["k"] = g.fetch("k", +"")
g["k"] << "z"
g["j"] = g["k"]
g["j"] << "!"
p g.to_a
