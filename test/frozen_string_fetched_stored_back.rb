# A frozen String fetched out of a boxed container and stored back is the
# object it was: a frozen literal taken as the default is still that
# literal, and it still refuses a change in place.
h = {}
h["k"] = h.fetch("k", "lit")
h["j"] = h.fetch("j", "lit")
begin
  h["k"] << "x"
rescue FrozenError => e
  p e.class
end
p h["k"].equal?(h["j"]), h["k"].equal?("lit"), h["k"].frozen?, h["k"]

a = ["z"]
a[1] = a.fetch(1, "lit")
a[1].upcase! if a.size > 5
p a[1].equal?("lit"), a[1].frozen?, a

f = ("a" + "b").freeze
g = {}
g[1] = g.fetch(1, f)
g[1] << "x" if g.size > 5
p g[1].equal?(f), g[1].frozen?

# one that is not frozen takes its append, as before
g[2] = g.fetch(2, +"m")
g[2] << "n"
p g[2], g[2].frozen?
