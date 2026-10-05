# partition with a Regexp evaluates its receiver once, also when nothing
# matches and the receiver is the first piece, and keeps its Array while
# the three pieces are made.

$calls = 0
def line
  $calls += 1
  "row" + $calls.to_s
end

# No match: the receiver is the first piece, and it ran once.
p line.partition(/z/)
p $calls
p line.partition(/w/)
p $calls

q = ["one", "two", "three"]
p q.pop.partition(/x/)
p q
p q.shift.partition(/n/)
p q

s = "ab"
p((s = s + "c").partition(/z/))
p s

# The match is set as =~ sets it.
p "key=value".partition(/(=)/)
p $~[0], $1, $`, $'
p "nothing".partition(/\d/)
p $~

# The pieces survive a collection.
t = "k1" * 3000 + "=" + "v" * 3000
bad = 0
i = 0
while i < 20000
  a = t.partition(/=/)
  bad += 1 if a.size != 3 || a[0].size != 6000 || a[1] != "=" || a[2].size != 3000
  i += 1
end
p bad
puts "hello world".partition(/o/).inspect
puts "héllo wörld".partition(/ö/).join("|")

# A String pattern and rpartition were right before and stay so.
p line.partition("z")
p line.rpartition(/z/)
p $calls
