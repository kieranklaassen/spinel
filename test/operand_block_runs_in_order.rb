# An operand that runs a block of its own (`xs.map { ... }`, a splatted
# `xs.select { ... }`) runs after the operands written before it.
def tick(n) = (puts "tick #{n}"; n)
def name(n) = (puts "name #{n}"; "s#{n}")
def arr(n) = (puts "arr #{n}"; [n, 1])
def list(n) = (puts "list #{n}"; [n, n])

xs = [1, 2]
ys = ["a", "b"]

# the receiver and the arguments of a builtin's call
p arr(8) + xs.map { |i| tick(i) }
p arr(8) - xs.select { |i| tick(i) }
p arr(8).concat(xs.select { |i| tick(i) })
p arr(8).zip(xs.sort_by { |i| -tick(i) })
p arr(8) == xs.map { |i| tick(i) }
p arr(8) | xs.reject { |i| tick(i) > 1 }
h = { 1 => [3] }
p h.fetch(tick(1), xs.map { |i| tick(i) })
p name(8).start_with?(*ys.map { |i| name(i) })

class K
  def two(a, b) = [a, b]
  def three(a, b, c) = [a, b, c]
  def rest(*a) = a
  def kw(a, k: 0) = [a, k]
  def [](a, b) = [a, b]
end

class L
  def two(a, b) = [b, a]
  def three(a, b, c) = [c, b, a]
  def rest(*a) = a.reverse
  def kw(a, k: 0) = [k, a]
  def [](a, b) = [b, a]
end

# a rest parameter's array, on a receiver of one class
k = K.new
p k.rest(tick(8), *xs.map { |i| tick(i) })
p k.rest(tick(8), xs.select { |i| tick(i) })
p k.rest(*list(7), xs.map { |i| tick(i) })

# a receiver that is one of two classes
[K.new, L.new].each do |r|
  p r.two(tick(8), xs.select { |i| tick(i) })
  p r.two(tick(8), ys.map { |i| name(i) })
  p r.three(tick(8), tick(9), xs.sort_by { |i| -tick(i) })
  p r.three(tick(8), xs.map { |i| tick(i) }, tick(9))
  p r.kw(tick(8), k: xs.map { |i| tick(i) })
  p r[tick(8), xs.select { |i| tick(i) }]
  p r.two(tick(8), xs.map { |i| tick(i) }) { 1 }
end

# held in a local
r = [K.new, L.new][1]
p r.two(tick(8), xs.select { |i| tick(i) })

# A String answered before the block is read after it, as it was: bound
# ahead of the block it would miss what the block appends to it.
$buf = +"ab"
$n = 0
def get = ($n += 1; $buf)
rs = [K.new, L.new]
p rs[$n].two(get, xs.map { |i| $buf << "y"; i })
p k.rest(get, *xs.map { |i| $buf << "z"; i })
