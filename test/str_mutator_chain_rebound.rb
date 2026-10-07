# A call of a String mutator chain can give the variable another String:
# the chain's last mutator then changes the String the chain ran on, and
# the variable keeps the one it was given.
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

# through a proc, and only on the pass that rebinds
t = +"abc"
f = -> { t = +"q"; "x" }
t.insert(0, "a").concat(f.call)
p t
u = +"abc"
n = 0
g = -> { n += 1; u = +"q" if n == 2; "x" }
3.times { u.prepend("p").concat(g.call) }
p u

# a global and an instance variable, through a method that assigns them
$g = +"abc"
def reset = ($g = +"q"; "x")
$g.insert(0, "a").concat(reset)
p $g
class Box
  attr_reader :s
  def initialize = @s = +"abc"
  def reset = (@s = +"q"; "x")
  def name = "x"
  def go = @s.insert(0, "a").concat(reset)
  def keep = @s.insert(0, "a").concat(name)
end
x = Box.new
x.go
p x.s
# a call that assigns nothing: the chain reaches the variable as before
y = Box.new
y.keep
p y.s

# through a clear, and at a last slice!, the same
v = +"abc"
v.clear.concat((v = +"q"; "x"))
p v
w = +"abc"
w.concat("x").slice!((w = +"zzz"; 0))
p w
$h = +"abc"
def tail = "x"
$h.clear.concat(tail)
p $h
