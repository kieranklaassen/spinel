# Hash[h] is a new Hash of h's entries: a change to either leaves the other.

g = {"a" => 1}
c = Hash[g]
c["b"] = 2
p g.to_a
p c.to_a
p c.equal?(g)
p c == {"a" => 1, "b" => 2}

s = {"a" => "x", "b" => "y"}
t = Hash[s]
s.delete("a")
p s.to_a
p t.to_a

i = {1 => 1, 2 => 2}
j = Hash[i]
j[3] = 3
i.clear
p i.size
p j.to_a

n = {1 => "x"}
o = Hash[n]
o[2] = "y"
p n.to_a
p o.to_a

m = {"a" => 1, "b" => "s"}
q = Hash[m]
q["c"] = nil
p m.size
p q.size

k = {a: 1, 1 => 1}
r = Hash[k]
r[:n] = 5
p k.to_a
p r.to_a

f = {1.5 => 1}
u = Hash[f]
u[2.5] = 2
p f.to_a
p u.to_a

y = {a: 1, b: 2}
z = Hash[y]
z[:c] = 3
p y.to_a
p z.to_a

# the copy does not take the default
d = Hash.new(0)
d["a"] += 1
e = Hash[d]
p e["a"]
p e["zz"]
p d["zz"]

# a Hash a call answers, and an empty one
def mk(n) = {"k#{n}" => n}
v = Hash[mk(4)]
p v.to_a
w = Hash[{}]
p w.size

# to_h still answers the Hash itself
x = g.to_h
p x.equal?(g)

# a Hash held in a boxed slot
row = [{"a" => 1}, 5]
bc = Hash[row[0]]
bc["b"] = 2
p row[0].size
p bc.size
ng = ARGV.size > 3 ? nil : {"a" => 1}
nc = Hash[ng]
nc["b"] = 2
p ng.size
p nc.size

# a call that changes or keeps what Hash[] answers gets the copy; one
# that only reads it does not need it
x = {"a" => 1, "b" => 2}
Hash[x].delete("a")
p x.size
p Hash[x].merge!({"z" => 9}).size, x.size
p Hash[x].equal?(x), Hash[x].size, Hash[x] == x, Hash[x]["b"]
Hash[x].each { |k, _v| x.delete(k) }
p x.size
