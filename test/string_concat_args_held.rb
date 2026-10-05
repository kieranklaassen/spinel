# concat and prepend with several arguments read them in order, and hold
# each while the next is made. The arguments were nested in one C
# expression: the text one of them made was held by nothing while the next
# was built, and which of the two was built first was the C compiler's
# choice. Each round goes through a local, a receiver that is no variable,
# an element, an instance variable and an Integer among the arguments, as a
# value and as a statement, and counts the results that are not Ruby's.
class Box
  attr_reader :s

  def initialize(i)
    @s = +"r#{i}"
  end

  def add(i) = @s.concat("a#{i}", "b#{i}")
  def pre(i) = @s.prepend("a#{i}", "b#{i}")
end

def mk(i) = +"m#{i}"

bad = 0
300.times do |i|
  a = "a#{i}"
  b = "b#{i}"
  c = "c#{i}"
  s = +"r#{i}"
  x = s.concat("a#{i}", "b#{i}")
  bad += 1 unless x == "r#{i}" + a + b && s == x
  s = +"r#{i}"
  x = s.prepend("a#{i}", "b#{i}")
  bad += 1 unless x == a + b + "r#{i}" && s == x
  s = +"r#{i}"
  s.prepend("a#{i}", "b#{i}", "c#{i}")
  bad += 1 unless s == a + b + c + "r#{i}"
  x = mk(i).concat("a#{i}", "b#{i}", "c#{i}")
  bad += 1 unless x == "m#{i}" + a + b + c
  x = mk(i).prepend("a#{i}", "b#{i}")
  bad += 1 unless x == a + b + "m#{i}"
  q = [+"k#{i}", 1]
  q[0].concat("a#{i}", "b#{i}")
  bad += 1 unless q[0] == "k#{i}" + a + b
  q[0].prepend("b#{i}", "c#{i}")
  bad += 1 unless q[0] == b + c + "k#{i}" + a + b
  e = [+"k#{i}"]
  e.first.concat("a#{i}", "b#{i}")
  bad += 1 unless e == ["k#{i}" + a + b]
  o = Box.new(i)
  x = o.add(i)
  bad += 1 unless x == "r#{i}" + a + b && o.s == x
  x = o.pre(i)
  bad += 1 unless x == a + b + "r#{i}" + a + b && o.s == x
  s = +"r#{i}"
  x = s.concat("a#{i}", 98, "c#{i}")
  bad += 1 unless x == "r#{i}" + a + "b" + c
end
p bad

# each argument is read after the one before it
n = 0
s = +"s"
p s.concat((n = 1; "x"), n.to_s)
n = 0
t = +"t"
p t.prepend((n = 2; "x"), n.to_s)
q = [+"abc"]
n = 0
q.push(+"d").first.concat((n = 3; "x"), n.to_s)
p q

# the receiver among its own arguments is appended as it was
s = +"ab"
p s.concat(s, s)
p s
