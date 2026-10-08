# spinel: int64 -- assumes a 64-bit Integer (values or arithmetic past 2^31); not run on a 32-bit target
# A Rational whose numerator or denominator is a Bignum is a Hash key like
# any other value: an equal Rational finds it. Its hash went by value
# already; the key comparison had no arm for it, so every lookup missed.

x = [Rational(2**70, 3), :a][0]
k = [Rational(2**70, 3), :a][0]
n = [Rational(2**70, 5), :a][0]
h = { x => 1, "k" => 2 }
p h[k], h.key?(k), h.fetch(k, :none), h.include?(k)
p h[n], h.key?(n), h.fetch(n, :none)
p x.eql?(k), x == k, x.hash == k.hash
p [x, k].tally.size, [x, k, n].tally.size
h[k] = 5
p h.size, h[x]
h[n] = 6
p h.size, h[[Rational(2**70, 5), :a][0]]
p h.delete(k), h.size, h[x]

# a denominator past a word, and a negative value
d = [Rational(3, 2**70), :a][0]
m = [Rational(-(2**70), 3), :a][0]
t = { d => :den, m => :neg }
p t[[Rational(3, 2**70), :a][0]], t[[Rational(-(2**70), 3), :a][0]], t[x]

# An operation's answer stays a Rational of Bignums when its parts fit a
# word again: it is the key the word-sized Rational of that value is.
y = x / (2**70)
w = [Rational(1, 3), :a][0]
p y, w, y == w, y.eql?(w)
g = { w => :word }
p g[y], g.key?(y)
g2 = { y => :big }
p g2[w], g2.key?(w), g2[[Rational(2, 3), :a][0]]

# keys of other classes beside it are found as before
mix = { x => 1, 7 => 2, "s" => 3, :s => 4, 2.5 => 5, [1, 2] => 6, w => 7 }
p mix[k], mix[7], mix["s"], mix[:s], mix[2.5], mix[[1, 2]], mix[[Rational(1, 3), :a][0]]

require "set"
s = Set.new([x, w])
p s.include?(k), s.include?(y), s.include?(n), s.size
