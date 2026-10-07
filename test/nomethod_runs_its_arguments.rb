# A call no method answers evaluates its arguments before it raises
# NoMethodError, as CRuby does: a call with a splat or a keyword argument
# raised without running any of them.

def tick(n)
  puts "tick #{n}"
  n
end

def boom(n)
  puts "boom #{n}"
  raise IOError, "io #{n}"
end

def mkblk(n)
  puts "blk #{n}"
  proc { 1 }
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

# a splat, a keyword, a double splat, a String key
try { r.zork(tick(1), *xs) }
try { r.zork(k: tick(2)) }
try { r.zork(**{ k: tick(3) }) }
try { r.zork(tick(4), **h) }
try { r.zork("a" => tick(5)) }
try { r.zork(*xs, tick(6), k: tick(7)) }

# the same on a typed receiver and on nil
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
try { r.zork(tick(18), *xs, &mkblk(18)) }
try { t.zork(*xs, **h, &mkblk(19)) }

# an argument's own raise wins over NoMethodError
try { r.zork(tick(20), *boom(20)) }
try { r.zork(*xs, k: boom(21)) }
try { t.zork(boom(22), *xs) }

# a literal beside an argument that runs
try { r.zork([1, 2], *xs, k: tick(31)) }
try { t.zork(**{ a: 1 }, k: tick(32)) }

# what an argument hoists ahead of its statement runs in its place
try { recv(40, t).zork(k: [1, 2].map { |i| tick(40 + i) }) }
try { r.zork(tick(43), [4, 5].map { |i| tick(40 + i) }, *xs) }
try { recv(46, r).zork({ a: tick(46) }, *xs) }
try { recv(47, r).zork(k: [tick(47), 1]) }

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
