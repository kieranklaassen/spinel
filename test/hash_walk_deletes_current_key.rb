# A block that deletes the entry its walk is at: the next entry slides into
# the slot, and the walk goes on from it, whatever the keys are.

# String keys
h = {"a" => 1, "b" => 2, "c" => 3}
h.each { |k, _v| h.delete(k) }
p h.to_a
h = {"a" => 1, "b" => 2, "c" => 3}
h.each_pair { |k, _v| h.delete(k) if k == "a" }
p h.to_a
h = {"a" => "x", "b" => "y", "c" => "z"}
h.each_key { |k| h.delete(k) }
p h.to_a
h = {"a" => "x", "b" => "y", "c" => "z"}
h.each_value { |v| h.delete(h.key(v)) }
p h.to_a

# a key after the one the walk is at, and one before it
h = {"a" => 1, "b" => 2, "c" => 3}
seen = []
h.each { |k, _v| seen << k; h.delete("c") if k == "a" }
p seen
p h.to_a
h = {"a" => 1, "b" => 2, "c" => 3}
seen = []
h.each { |k, _v| seen << k; h.delete("a") if k == "b" }
p seen
p h.to_a

# String keys with values of two kinds
q = {"a" => 1, "b" => "s", "c" => nil}
q.each { |k, _v| q.delete(k) }
p q.to_a

# keys of two kinds, and Float keys
m = {"a" => 1, :b => 2, 3 => 3, 1.5 => 4}
m.each { |k, _v| m.delete(k) }
p m.to_a
m2 = {"a" => 1, :b => 2, 3 => 3, 1.5 => 4}
m2.each_key { |k| m2.delete(k) if k != :b }
p m2.to_a
m3 = {"a" => 1, :b => 2, 3 => 3, 1.5 => 4}
c = 0
m3.each_value { |v| c += v; m3.delete(1.5) if v == 1 }
p c
p m3.to_a
f = {1.5 => 1, 2.5 => 2, 3.5 => 3}
f.each { |k, _v| f.delete(k) }
p f.to_a

# each_key and each_value over Symbol and Integer keys
s = {a: 1, b: 2, c: 7}
s.each_key { |k| s.delete(k) }
p s.to_a
s2 = {a: 1, b: 2, c: 7}
s2.each_value { |v| s2.delete(s2.key(v)) }
p s2.to_a
i = {1 => 1, 2 => 2, 3 => 7}
i.each_key { |k| i.delete(k) }
p i.to_a
i2 = {1 => "x", 2 => "y", 3 => "z"}
i2.each_value { |v| i2.delete(i2.key(v)) }
p i2.to_a

# clear, shift, break and next inside the walk
h = {"a" => 1, "b" => 2, "c" => 3}
t = 0
h.each { |_k, _v| t += 1; h.clear }
p t
h = {"a" => 1, "b" => 2, "c" => 3}
t = 0
h.each { |_k, _v| t += 1; h.shift }
p t
p h.to_a
h = {"a" => 1, "b" => 2, "c" => 3}
h.each { |k, _v| h.delete(k); break }
p h.to_a
h = {"a" => 1, "b" => 2, "c" => 3}
h.each { |k, v| next if k == "b"; h[k] = v + 1; h.delete(k) if k == "a" }
p h.to_a
