# String#replace takes a copy of its argument's bytes. An argument made
# for the call (`s.replace(s.upcase)`) was held by nothing while the
# copy was allocated: a collection there freed it, and the receiver
# took whatever the freed bytes then held.

def id(s) = s

q = "ab".dup
q.replace("x" + "yz")
p q
q.replace(q.upcase)
p q
q.replace(q + "c")
p q
n = 5
q.replace(n.to_s)
p q
q.replace("v#{q.size}w")
p q
q.replace([1, 2].map { |i| i.to_s }.join("-"))
p q
q.replace(format("%05d", 42))
p q
q.replace(id("wxyz").dup)
p q

# in a block, in a method, on an instance variable and a global
[1, 2].each { |i| q.replace("r" + i.to_s) }
p q
def fill(s)
  s.replace("in " + "fill")
  s
end
p fill("ab".dup)
class Holder
  def initialize = @s = "ab".dup
  def go
    @s.replace("iv" + "ar")
    @s
  end
end
p Holder.new.go
$g = "ab".dup
$g.replace("glo" + "bal")
p $g

# a source a name already holds is copied as before
y = "held".dup
q.replace(y)
p q, y, q.equal?(y)

# long Strings, many rounds: a plain run answered wrong
bad = 0
i = 0
while i < 400
  q.replace("x" * 300_000 + i.to_s)
  bad += 1 unless q.size == 300_000 + i.to_s.size && q.start_with?("xxxx") && q.end_with?(i.to_s)
  i += 1
end
p bad
