# An argument of a String mutator chain can assign the chain's variable:
# the rest of the chain then changes the String it ran on, and the
# variable keeps the one it was given.
a = +"abc"
a.insert(0, "a").concat((a = +"q"; "x"))
p a
b = +"abc"
b.prepend("a").replace((b = +"q"; "x"))
p b
c = +"abc"
c.replace("a") << (c = +"q"; "x")
p c
d = +"abc"
d.upcase!.sub!((d = +"q"; "A"), "z")
p d
# the assignment as the argument itself, `+=`, a dup, an interpolation,
# a multiple assignment
e = +"abc"
e.insert(0, "a").concat(e = +"q")
p e
f = +"abc"
f.insert(0, "a").concat((f += "z"; "x"))
p f
g = +"abc"
g.insert(0, "a").concat((g = g.dup; "x"))
p g
h = +"abc"
h.insert(0, "a").concat((h = "is #{h}"; "x"), "y")
p h
n = 1
o = +"abc"
o.insert(0, "a").concat((n, o = 2, +"q"; "x"))
p o, n
# the links after it leave the variable alone too
i = +"abc"
i.insert(0, "a").concat((i = +"q"; "x")).upcase!.concat("y" * 2)
p i
j = +"abc"
j.concat("1").upcase!.sub!("A", (j = +"q"; "z" + "w")).concat("!")
p j
# what the variable was given can be changed after
k = +"abc"
k.insert(0, "a").concat((k = +"q"; k << "y"; "x"))
p k

# a global, an instance variable and a class variable
$g = +"abc"
$g.insert(0, "a").concat(($g = +"q"; "x"))
p $g
class Box
  attr_reader :s
  def initialize = @s = +"abc"
  def go = @s.insert(0, "a").concat((@s = +"q"; "x"))
  def add = @s.prepend("a").concat((@s += "z"; "x")).upcase!
  def tidy = (@s.chomp!; "x")
  def keep = @s.insert(0, "a").concat(tidy)
  @@c = +"abc"
  def self.go = @@c.insert(0, "a").concat((@@c = +"q"; "x"))
  def self.c = @@c
end
x = Box.new
x.go
p x.s
y = Box.new
p y.add, y.s
Box.go
p Box.c

# no assignment for certain: the chain reaches the variable as before
z = Box.new
z.keep
p z.s
l = +"abc"
l.insert(0, "a").concat((l = +"q" if l.size > 9; "x"))
p l
m = +"a-b"
m.insert(0, "a").concat((m.strip!; "x"))
p m
# nor where a later link may assign it: every link writes back, as before
u = +"ab"
u.insert(0, "").concat((u = +"ab1"; "")).concat((u = +"zz" if u.size > 9; (u.size - 1).to_s))
p u
