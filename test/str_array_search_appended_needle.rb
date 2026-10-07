# A boxed String the program appends to is kept as a shared handle. The
# searches of a typed String Array tested the needle's tag for a String
# alone, so with such a needle include?, member?, index, find_index and
# rindex answered false or nil and delete removed nothing.
h = { "k" => +"a", "n" => 1 }
h["k"] << "b"
a = ["ab", "c", "ab", "abc", ""]
p a.include?(h["k"]), a.member?(h["k"])
p a.index(h["k"]), a.find_index(h["k"]), a.rindex(h["k"])
puts(a.include?(h["k"]) ? "y" : "n")
p !a.include?(h["k"])
def has(a, v) = a.include?(v)
def at(a, v) = a.index(v)
p has(a, "zz"), at(a, "c"), has(a, h["k"]), at(a, h["k"])
t = h["k"]
p a.rindex(t)
p a.delete(h["k"]) { |v| v.to_s + "?" }, a
p a.delete(h["k"]) { |v| v.to_s + "?" }
b = %w[ab c ab abc]
p b.delete(h["k"]), b, b.delete(h["k"])
# the element answered is the Array's own, not the needle
c = ["ab", "c"]
d = c.delete(h["k"])
h["k"] << "!"
p d, h["k"], c.include?(h["k"]), c.index(h["k"])
# a boxed Array as the receiver
g = { "a" => ["ab!", "c", "ab!"], "n" => 1 }
p g["a"].include?(h["k"]), g["a"].index(h["k"]), g["a"].rindex(h["k"])
p g["a"].delete(h["k"]), g["a"]
# an empty appended String, and the kinds that are not a String
e = { "k" => +"", "n" => 1 }
e["k"] << ""
p ["x", ""].include?(e["k"]), ["x", ""].index(e["k"])
p a.include?(h["n"]), a.index(h["n"]), a.include?(h["zz"]), a.delete(h["n"])
# a frozen Array answers nil for a needle it does not hold, and raises
# for one it holds
f = ["x", "y"].freeze
p f.delete(h["k"]), f.delete(h["k"]) { "none" }
q = { "a" => ["x"].freeze, "n" => 1 }
p q["a"].delete(h["k"])
w = ["ab!", "y"].freeze
begin
  w.delete(h["k"])
rescue FrozenError
  puts "frozen"
end
p f, w
