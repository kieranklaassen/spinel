# merge hands the receiver's default proc to the Hash it builds through a
# context allocated after that Hash. The allocation can collect, the new
# Hash is old after it, and the context was stored with no write barrier:
# the next minor collection freed it, and a missing key called through it.
names = Hash.new { |hash, k| "no #{k}" }
names[2] = "b"
m = names.merge({ 3 => "c" })
p [m[1], m[2], m[3]]

# nothing is stored into the merge of two empty Hashes, so nothing else
# records it either
empty = Hash.new { |hash, k| "none #{k}" }
extra = {}
e = empty.merge(extra)
spare = Array.new(8) { |i| [i] }
p e[4], e.size, spare.size

# a block, a second merge, and a receiver known only at run time
words = { "a" => 1, "b" => "x" }
words.default_proc = proc { |hash, k| "word #{k}" }
w = words.merge({ "b" => 2.5 }) { |k, old, new| old }
p [w["a"], w["b"], w["q"]]
twice = names.merge({ 3 => "c" }).merge({ 4 => "d" })
p [twice[4], twice[5]]
row = [names, 1]
r = row[0].merge({ 9 => "i" })
p [r[9], r[10]]
