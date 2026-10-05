# The inference fixpoint has a 128-round cap. Reaching it is not a slow path,
# it is a non-answer: the loop stops because the cap says so, mid-oscillation,
# and where it stops decides which of two typings gets emitted. Both typings
# usually pass the test -- a boxed slot prints the same answer as a typed one --
# so nothing else in the suite can see it. (#4116)
#
# `require "pathname"` alone used to reach the cap, twice, and cost a 53k-line
# tree 124.6s in the front end against 11.5s converged.
require "pathname"

# A few shapes that were capped for their own reasons: IO.pipe's two targets,
# a case/in binding, and a File.open block parameter.
r, w = IO.pipe
w.write("x")
w.close
puts r.read

case [1, "a"]
in [Integer => n, String => s]
  puts "#{n}#{s}"
end

p Pathname.new(".").directory?

# An empty `{}` the caller then writes into, handed to a parameter that is
# poly (a second call site passes another hash kind). The reverse binding
# widened the local to the PolyPoly hash (#3158); its own element writes
# re-derived the StrStr kind every round; to the cap, every compile.
def store(h, n)
  h[n] ||= n * 10
end
sub = {}
sub["body"] = "hi"
store(sub, 1)
store({ 2 => 3 }, 2)
p sub

# A method that stores into its parameter under a String key, handed values
# of two kinds: a Hash a block widened a round after the call first bound it,
# a Hash and nil, two kinds of Hash, a Hash and nil by keyword. The binding
# boxed the parameter, its own store typed it String-keyed again, and the
# next round's binding boxed it again; to the cap.
def fc_label(x)
  x["a"] = "q"
end
late = { "a" => "x" }
[1].each { |k| late[k] = "s" }
fc_label(late)
def fc_label_some(x)
  x["a"] = "q" if x
end
some = { "a" => "x" }
fc_label_some(some)
fc_label_some(nil)
def fc_label_both(x)
  x["a"] = "q"
end
strs = { "a" => "x" }
ints = { "c" => 3 }
fc_label_both(strs)
fc_label_both(ints)
def fc_label_named(x:)
  x["a"] = "q" if x
end
named = { "a" => "x" }
fc_label_named(x: named)
fc_label_named(x: nil)
p late, some, strs, ints, named

# Four more shapes, each to the cap for its own reason (#4962).
#
# A table the object-array narrowing withdrew: `fc_pair`'s value narrowed to
# an int-array table before `FcBox.new(qr[0])` had widened the ivar, and the
# decision it then withdrew came back every round as a pin.
def fc_pair(a) = [a, []]
class FcBox
  attr_reader :v
  def initialize(v) = @v = v
end
fb = FcBox.new([1, 2])
qr = fc_pair(fb.v)
fb = FcBox.new(qr[0])
p fb.v

# A string range's block-driven step, lowered to `step(n).each { }` and folded
# straight back by the Enumerator#each rule.
fs = []
("a".."e").step(2) { |s| fs << s }
p fs

# Two procs of different return types in one local: each write reported
# a change of the local's proc return type.
fsh = ->(x) { x }
fsh = ->(a, b, c) { a + b + c }
p fsh.curry(3).call(1).call(2).call(3)

# A parameter widened by a push, bound from an int-array ivar: the two-kinds
# rule and the push rule answered it in turn.
module FcHeld
  def self.add(into) = into.push("pushed")
end
class FcNamed
  def initialize = @a = [0]
  def go = FcHeld.add(@a)
  def out = @a
end
fn = FcNamed.new
fn.go
p fn.out

# A *rest parameter the body reassigns from itself (`args = args.first`, the
# background job's perform(*args)), as a statement of the body and inside a
# branch: the desugared copy must not keep the fold alternating (#6491)
def fp_perform(*args)
  args = args.first
  args
end
def fp_maybe_first(*a)
  if a.size > 0
    a = a.first
  end
  a
end
p fp_perform(7), fp_maybe_first(7), fp_maybe_first
