# Symbol#[] is its name's: a String index answers the substring when the
# name holds it. Through a boxed receiver it answered nil.

def pick(n) = n > 0 ? {a: 1} : :stone

s = pick(0)
p s["ton"]
p s["zz"]
p s[""]
p s["stone"]

# an index the name does not hold: one that starts as the name does, one
# longer than the name, one with a NUL after bytes the name holds
p s["sx"]
p s["stonewall"]
p s["to\0n"]
p s["ne"]

# a name made at run time
def made(n) = n > 0 ? {a: 1} : ("sto" + "ne").to_sym
d = made(0)
p d["ton"]
p d["tx"]
p d["zz"]

# the index boxed too
k = ["on", 0][0]
p s[k]

# the answer is a new String, not the index and not frozen
k2 = "to" + "n"
r = s[k2]
p r.equal?(k2)
q = s["ton"]
p q.frozen?
q.concat("x")
p q
p s["ton"]

# a method that takes either
def name_part(o, k) = o[k]
p name_part(s, "st")
p name_part({"st" => 1}, "st")

# the other indexes of a Symbol answer as before, and so does a String's
p s[1]
p s[0..1]
p s[/o./]
t = [+"stone", 5][0]
p t["ton"]
p t["zz"]
