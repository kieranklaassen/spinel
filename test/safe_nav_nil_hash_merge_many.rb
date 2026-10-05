# `h&.merge(a, b)` on a nil Hash answers nil and runs neither argument; a
# Hash that is not nil merges each argument once, in order.

$log = []
def lg(x) = ($log << x.to_a; x)
def hsh(v) = v ? {a: 1} : nil

h = hsh(false)
p h&.merge(lg({b: 2}), lg({c: 3})), $log
r = h&.merge(lg({b: 2}), lg({c: 3}), lg({d: 4}))
p r.nil?, $log

h = hsh(true)
p h&.merge(lg({b: 2}), lg({c: 3})).to_a, $log
p h.to_a
$log = []
r = h&.merge(lg({b: 2}), lg({c: 3}), lg({d: 4}))
p r.to_a, $log

# merge! changes the receiver, or nothing
$log = []
h = hsh(false)
h&.merge!(lg({b: 2}), lg({c: 3}))
p h, $log
h = hsh(true)
h&.merge!(lg({b: 2}), lg({c: 3}))
p h.to_a, $log

# a conflict block at every step
h = hsh(false)
p h&.merge({a: 5}, {a: 6}) { |k, x, y| x + y }
h = hsh(true)
p h&.merge({a: 5}, {a: 6}) { |k, x, y| x + y }.to_a

# a String-keyed Hash
def shsh(v) = v ? {"a" => 1} : nil
$log = []
s = shsh(false)
p s&.merge(lg({"b" => 2}), lg({"c" => 3})), $log
s = shsh(true)
p s&.merge(lg({"b" => 2}), lg({"c" => 3})).to_a, $log

# one argument, as before
h = hsh(false)
p h&.merge({b: 2})
h = hsh(true)
p h&.merge({b: 2}).to_a
