# A `&.` call on a receiver that is not nil runs after what is written before
# it, and one on a nil receiver runs nothing. Where the call's value hoisted a
# statement (an argument that is made, or that runs), the guard stood ahead of
# the statement with the call inside it, so `$c` below was read after `bump`.
$c = 0
$log = []
def lg(x) = ($log << x; x)
class K
  attr_reader :v
  def initialize = (@v = 0)
  def bump(a) = ($c += 1; @v += 1; a)
  def say(s) = puts(s)
end
def mk(v) = v ? K.new : nil

# not nil: the call stays in its place
o = mk(true)
r = "#{$c} #{o&.bump([1, 2])}"; p r
r = ($c == 1 ? 10 : 20) + (o&.bump([1, 2]) || []).size; p r
x, y = $c, o&.bump([3]); p x, y
r = "#{o.v} #{o&.bump("a#{$c}")} #{o.v}"; p r
r = "#{$c} #{o&.bump({ k: $c }).size}"; p r
r = "#{$c} #{o&.bump(lg(1))}"; p r, $log
n = 0
r = "#{$c} #{o&.bump(n += 1)}"; p r, n
# an answer with no C value
o&.say("s#{$c}")
p o&.say("v#{$c}")

# nil: nothing runs
o = mk(false)
$log.clear
n = 0
r = "#{$c} #{o&.bump([1, 2])}"; p r
r = "#{$c} #{o&.bump(lg(1))}"; p r, $log
r = "#{$c} #{o&.bump(n += 1)}"; p r, n
x, y = $c, o&.bump([lg(2)]); p x, y, $log
o&.say("n#{$c}")
def f(v) = v&.then { _1 * 2 }
p f(nil), f(3)
# below a function's top scope, where a hoisted temp's root is not a frame entry
def each2(o) = [0, 1].map { |i| "#{$c} #{o&.bump("q#{i}")}" }
p each2(mk(true)), each2(mk(false))
