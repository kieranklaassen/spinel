# A call no method answers evaluates its arguments before it raises
# NoMethodError, as CRuby does. A boxed receiver's dispatch runs the
# arguments it binds ahead of the call. A receiver of one known class
# raised without running any when one was a splat or a keyword argument.
# They run where each is of a listed shape: a plain write of a variable,
# or a call, in top-level code, of a top-level method that does nothing
# but read and write variables, print an Integer or a text, raise, and
# call such methods.

def tick(n)
  puts "tick #{n}"
  n
end

def boom(n)
  puts "boom #{n}"
  raise IOError, "io #{n}"
end

def mkblk(n, b)
  puts "blk #{n}"
  b
end

def recv(n, v)
  puts "recv #{n}"
  v
end

def try
  yield
rescue NoMethodError, IOError => e
  puts "#{e.class}: #{e.message.tr("`", "'")}"
end

xs = [1]
h = { k: 1 }
blk = proc { 1 }
r = ARGV.size > 5 ? "s" : 5   # a boxed receiver
t = 5                         # a typed one

# a boxed receiver: a splat, a keyword, a double splat, a String key
try { r.zork(tick(1), *xs) }
try { r.zork(k: tick(2)) }
try { r.zork(**{ k: tick(3) }) }
try { r.zork(tick(4), **h) }
try { r.zork("a" => tick(5)) }
try { r.zork(*xs, tick(6), k: tick(7)) }

# a typed receiver and nil: none of these ran
try { t.zork(tick(8), *xs) }
try { t.zork(k: tick(9)) }
try { nil.zork(tick(10), *xs) }
try { "str".zork(tick(11), *xs) }
try { [1].zork(tick(12), k: 1) }
try { :sym.zork(*xs, tick(13)) }
try { 1.5.zork(tick(14), *xs) }

# the receiver first, then the arguments, then the block argument
try { recv(15, r).zork(tick(15), *xs) }
try { recv(16, t).zork(tick(16), k: tick(17)) }
try { r.zork(tick(18), *xs, &mkblk(18, blk)) }
try { t.zork(*xs, **h, &mkblk(19, blk)) }

# an argument's own raise wins over NoMethodError
try { r.zork(tick(20), *boom(20)) }
try { r.zork(*xs, k: boom(21)) }
try { t.zork(boom(22), *xs) }

# a literal beside an argument that runs
try { r.zork([1, 2], *xs, k: tick(31)) }
try { t.zork(**{ a: 1 }, k: tick(32)) }

# inside an Array or a Hash literal, in the order they are written
try { recv(46, r).zork({ a: tick(46) }, *xs) }
try { recv(47, t).zork(k: [tick(47), 1]) }
try { t.zork(k: { "a" => tick(48), b: [tick(49)] }) }

# the call's value used
try { r.zork(tick(23), *xs).to_s }
try { x = t.zork(tick(24), *xs); p x }
try { p(r.zork(k: tick(25)) + 1) }

# as before: plain arguments, a block, a literal splat
try { r.zork(tick(26)) }
try { r.zork(tick(27), &blk) }
try { r.zork(*[tick(28)]) }
try { t.zork(tick(29)) }
try { r.zork(tick(30)) { 1 } }

# the receiver is the object its variable held before the arguments ran:
# an argument that assigns the variable does not change what is raised for
def held
  yield
rescue NoMethodError => e
  puts "#{e.receiver.inspect}: #{e.message.tr("`", "'")}"
end

def npick(c) = c > 5 ? 3 : nil

def run1(f) = f.call

class Box
  def initialize
    @n = 5
    @s = "ab"
  end

  def run
    held { @n.zork(k: (@n = 7)) }
    held { @s.zork(k: (@s = "cd")) }
    p @n, @s
  end
end

u = 5
held { u.zork(k: (u = 7)) }
s = "ab"
held { s.zork(*(s = "cd"; xs)) }
n = npick(ARGV.size)
held { n.zork(k: (n = 7)) }
$g = 5
def gset = ($g = 8)
held { $g.zork(k: gset) }
@m = 5
held { @m.zork(k: tick(50)) }
K = 5
held { K.zork(k: tick(51)) }
w = 5
begin
  w.zork(k: (w = 7))
rescue NoMethodError => e
  puts "#{e.receiver.inspect}: #{e.message.tr("`", "'")}"
end
a = [1, 2]
held { a.zork(k: (a = [9])) }
held { [u, 1].zork(k: (u = 8)) }
p u, s, n, $g, w, a
Box.new.run

# an argument of any other shape is not run, and the call raises as it did
z = 5
lz = [1, 2].lazy.map { |x| z = 7; x }
begin
  z.zork(k: lz.first)
rescue NoMethodError => e
  puts "#{e.receiver.inspect}: #{e.message.tr("`", "'")}"
end
try { 5.zork(k: (U = 7)) }
if ARGV.size > 5
  t.zork(k: (V = 7))
end
try { 5.zork(k: global_variables.size) }
v = 5
set = -> { v = 9 }
held { v.zork(k: run1(set)) }

# a long name in the nil test of a receiver that may be nil
Aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa = "ab"
try { Aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.zork }
try { Aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.zork(k: tick(52)) }
