# An append chain written as a statement on a receiver that is a call: the
# receiver runs once, ahead of the chain, however many links follow it.
# Written out at each link it ran once a link: an Array lost two elements,
# a counter moved twice.
$n = 0
class Q
  attr_reader :s
  def initialize(s) = @s = s
  def b
    $n += 1
    @s
  end
  def me
    $n += 1
    self
  end
end
def mk
  $n += 1
  Q.new(+"m")
end
def nx
  $n += 1
end
def three = [Q.new(+"p"), Q.new(+"q"), Q.new(+"r")]

# a receiver that removes what it answers
a = three
c = a.dup
a.shift.s << "x" << "y"
p c.map(&:s), a.size

a = three
c = a.dup
a.pop.s << "x" << "y" << "z"
p c.map(&:s), a.size

# an index that moves
a = three
i = -1
a[i += 1].s << "x" << "y"
p a.map(&:s), i

a = three
a[nx - 1].s.concat("x").concat("y")
p a.map(&:s), $n

# an Enumerator
a = three
e = a.each
e.next.s << "x" << "y"
p a.map(&:s), e.next.s

# a reader that counts its calls, through each spelling of the chain
$n = 0
k = Q.new(+"k")
k.b << "1" << "2"
k.b.concat("3").concat("4")
(k.b << "5") << "6"
k.b.concat("7") << "8"
p k.s, $n

$n = 0
k.me.s << "a" << "b" << "c"
k.me.b << "d" << "e"
p k.s, $n

# a method that makes the object
$n = 0
mk.s << "x" << "y"
mk.b << "x" << "y" << "z"
p $n

# an Integer link, an interpolation, a call as the argument
$n = 0
k = Q.new(+"k")
v = 7
k.b << 100 << 101
k.b << "a#{v}" << "b#{v + 1}"
k.me.s << 3.to_s << [1, 2].size.to_s
p k.s, $n

# one link whose argument has the receiver written again
$n = 0
k = Q.new(+"k")
k.b << 65
k.b << "a#{v}b#{v}"
p k.s, $n

# an argument that puts the receiver's own String back in its slot under a
# new handle: the slot is read again at each link
class W
  attr_reader :s
  def initialize = @s = +"s"
  def touch
    x = @s
    @s = x
    "w"
  end
end
o = W.new
o.s << "a#{o.touch}" << "b"
a = [o]
a.shift.s << "c#{o.touch}" << "d"
p o.s, a.size

# an argument that changes what the owner names: the first owner's String
# takes every link
a = [W.new, W.new]
b = a.dup
i = 0
a[i].s << "x" << (i = 1; "y")
a[0].s << "p" << (a.clear; "q")
p b.map(&:s), i, a.size

# under a condition, in a block and in a loop
$n = 0
k = Q.new(+"")
k.b << "x" << "y" if $n >= 0
2.times { k.b << "x" << "y" }
j = 0
while j < 2
  k.b << "x" << "y"
  j += 1
end
p k.s, $n

# nothing else holds the receiver while the arguments allocate
def pad(i) = ("z" * 30) + i.to_s
t = 0
20.times do |i|
  q = three
  q.shift.s << pad(i) << pad(i + 1)
  t += q.size
end
p t
