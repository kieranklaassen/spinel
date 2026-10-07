# spinel: int64 -- 2**70 is a Bignum; not run on a 32-bit target
# A proc, lambda or block parameter is a Bignum when some call passes one.
# An Integer another call passes rides the slot as itself; read as the
# pointer, 7 faults and 0 is nil, and a yield of one does not build.
digits = ->(n) { n.to_s.size }
puts digits.call(2**70)
puts digits.call(0)
show = proc { |n| p n }
show.call(2**70)
show.call(0)
show.call(-7)
show.call(ARGV.size + 9)
double = lambda { |n| n * 2 }
puts double.call(21)
puts double.call(2**70)

# a proc called through a second name, which types the parameter too
pr = proc { |e| p e + 1 }
pr.call(7)
qr = pr
qr.call(2**70)

# two parameters, each given both kinds
sum = proc { |a, b| a + b }
p sum.call(2**70, 1)
p sum.call(1, 2**70)
p sum.call(1, 2)
p sum.(3**50, 4), sum[5, 6]

# nil stays nil
maybe = proc { |n| n.nil? ? "none" : n.to_s }
puts maybe.call(2**70), maybe.call(nil), maybe.call(3)

# a block a method yields to, and one it calls
def each_total
  yield 2**70
  yield 7
end
each_total { |n| puts n }
def twice(&blk)
  blk.call(7)
  blk.call(2**70)
end
twice { |n| puts n + 1 }

# a Method's proc, a bound builtin's, a Symbol's
def shown(n) = puts(n)
m = method(:shown).to_proc
m.call(2**70)
m.call(7)
def ends(a, *r, z) = p([a, z, r.size])
e = method(:ends).to_proc
e.call(2**70, 1, 7)
e.call(7, 1, 2**70)
add5 = 5.method(:+).to_proc
p add5.call(2**70), add5.call(7)
size = :to_s.to_proc
puts size.call(2**70), size.call(7)

# the runtime's own call: case equality
big = proc { |n| n > 5 }
p(big === 2**70, big === 7, big === 3)

# the Bignum made of the Integer is kept while the body allocates
keep = proc { |n| pad = "x" * 64; [n, pad.size] }
p keep.call(2**70)
lost = 0
2000.times { |i| r = keep.call(i); lost += 1 unless r[0] == i }
p lost

# a proc and a lambda only ever given Bignums, every call in sight
def only_big
  pr = proc { |n| n + 1 }
  l = lambda { |n, m| n - m }
  [pr.call(2**70), pr.(2**71), l.call(2**70, 2**69)]
end
p only_big
