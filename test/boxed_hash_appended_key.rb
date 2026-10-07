# A Hash reached through a boxed value, asked with a key that is a boxed
# String the program has appended to: the key is a String, so it is found
# (it missed, as a key of another kind does).
h = { "k" => +"a", "n" => 1 }
h["k"] << "b"
q = { "si" => { "ab" => 1, "c" => 2 }, "ss" => { "ab" => "v", "c" => "w" }, "sp" => { "ab" => 1, "c" => "w" }, "n" => 1 }

%w[si ss sp].each do |name|
  t = q[name]
  p t[h["k"]], t.fetch(h["k"]), t.fetch(h["k"], 0), t.dig(h["k"])
  p t.key?(h["k"]), t.has_key?(h["k"]), t.include?(h["k"]), t.member?(h["k"])
  p t.values_at(h["k"], "c").size, t.slice(h["k"]).size
end
p q.dig("si", h["k"])

# the key a slice keeps does not follow a later append
r = q["si"].slice(h["k"])
h["k"] << "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
p r.keys[0].size, r["ab"]
p q["si"][h["k"]], q["si"].key?(h["k"]), q["si"].fetch(h["k"], :none)

# delete finds it too, once
d = { "k" => +"a", "n" => 1 }
d["k"] << "b"
p q["ss"].delete(d["k"]), q["ss"].size, q["ss"].delete(d["k"])

# a Hash keyed by Symbols or Integers has no such key
o = { "y" => { ab: 1 }, "i" => { 1 => "x" }, "n" => 1 }
p o["y"][d["k"]], o["y"].key?(d["k"]), o["i"][d["k"]], o["i"].key?(d["k"]), o["y"].delete(d["k"])
