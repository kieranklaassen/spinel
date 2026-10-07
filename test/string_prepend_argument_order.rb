# String#prepend takes its arguments, in order, before it reads its receiver:
# an argument that changes the receiver is seen, and with several arguments
# each is held while the next one is built.

def add(s) = (s << "y"; "z")

s = +"a-"
s.prepend((s << "y"; "z"))
t = +"a-"
t.prepend(add(t))
u = +"a-"
u.prepend((u.replace("k"); "z"))
p [s, t, u]

# the value, read in place
v = +"abc"
p v.prepend((v << " and a tail longer than its buffer"; "z"))
p v

# several arguments
w = +"abc"
w.prepend((w << "y"; "z"), (w << "w"; "q"))
x = +"abc"
r = x.prepend("q", (x << " and a tail longer than its buffer"; "z"))
p [w, x, r]

class Box
  def initialize = @s = +"a-"
  def grow = (@s << "y"; "z")
  def go
    @s.prepend(grow)
    @s
  end
  def value = @s.prepend(grow, grow)
end
b = Box.new
p b.go
p b.value

$g = +"a-"
$g.prepend(($g << "y"; "z"))
p $g

# each argument is held while the next one is built
def held
  n = 0
  a = [+"t", 1]
  300.times do |i|
    s = +"t"
    s.prepend("h#{i}-", "m#{i}-")
    u = +"t"
    u.prepend("h#{i}-", (u << "y#{i}"; "m#{i}-"))
    n += 1 if s == "h#{i}-m#{i}-t" && u == "h#{i}-m#{i}-ty#{i}"
  end
  [n, a[0].prepend("h#{n}-", "m#{n}-")]
end
p held
