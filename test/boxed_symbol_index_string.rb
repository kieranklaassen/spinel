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

# an index that is not whole characters is in no String, though the name
# holds its bytes; whole characters are
def wide(n) = n > 0 ? {a: 1} : :"héllo wörld"
w = wide(0)
p w["\xC3"]
p w["h\xC3"]
p w["\xA9l"]
b = "\xA9"
p w[b]
p w["é"].bytesize
p w["wör"].bytesize
def kanji(n) = n > 0 ? {a: 1} : :"日本語"
j = kanji(0)
p j["\xE6\x97"]
p j["\x97\xA5"]
p j["本"].bytesize

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

# a bare global, instance variable or class variable can be read after its
# index ran. Where the index may assign it, the read answers as it did:
# the name before the write holds no "cd"
og = { "a" => :ab, "b" => :cd, "k" => "cd", "s" => :stone, "t" => "ton" }
$ox = og["a"]
p $ox[($ox = og["b"]; og["k"])]
$ox = og["a"]
p $ox[begin; $ox = og["b"]; "cd"; end]
$ox = og["a"]
p $ox[1.then { $ox = og["b"]; "cd" }]
$ox = og["a"]
ol = [->(i) { $ox = og["b"]; i }, "cd"]
p $ox[(ol[0][0]; ol[1])]
class Slot
  def initialize(g) = (@g = g; @x = g["a"])
  def one = @x[(@x = @g["b"]; @g["k"])]
  def two = @x[begin; @x = @g["b"]; "cd"; end]
  @@x = nil
  def self.set(g) = (@@g = g; @@x = g["a"])
  def self.one = @@x[(@@x = @@g["b"]; @@g["k"])]
  def self.two = @@x[begin; @@x = @@g["b"]; "cd"; end]
  def self.name_part = @@x["a"]
  def name_part(i) = @x[i]
end
p Slot.new(og).one
p Slot.new(og).two
Slot.set(og); p Slot.one
Slot.set(og); p Slot.two
# a receiver that is a call, under a `case`
ob = [:ab, 5]
p ob[0][case ob.size when 2 then ob[0] = :cd; "cd" else "cd" end]

# where receiver and index run none of the program's code the name is
# searched
$ox = og["s"]
p $ox["ton"]
oi = "on"
p $ox[oi]
p Slot.new(og).name_part("b")
Slot.set(og); p Slot.name_part
ob = [:stone, 5]
p ob[0]["ton"]
