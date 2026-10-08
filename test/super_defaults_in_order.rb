# A `super` leaves the parent's optional parameters to their defaults, bare
# or with arguments. The defaults stood side by side in the call's
# parentheses, where C runs them in any order (gcc: the last first). Made
# ahead of the call, a default lives no longer than it did there.
# gc-stress-test runs this under SPINEL_GC_STRESS=2.

$n = 0
def bump = "u#{$n += 100}"

class Vec
  attr_reader :x, :y
  def initialize(x, y)
    @x = x
    @y = y
  end
end

class Base
  def pos(x = "a#{$n += 1}", y = "b#{$n += 1}", z = "c#{$n += 1}") = [x, y, z]
  def ints(x = ($n += 1), y = ($n += 1), z = ($n += 1)) = [x, y, z]
  def reads(x = $n, y = ($n += 1), z = ($n += 1)) = [x, y, z]
  def mixed(x = "a#{$n}", y = ($n += 1), z = "c#{$n}") = [x, y, z]
  def keys(x: "a#{$n += 1}", y: "b#{$n += 1}", z: "c#{$n += 1}") = [x, y, z]
  def cond(f, x = "a#{$n += 1}", y = "b#{$n += 1}") = [x, y]
  def rest(x = "a#{$n += 1}", y = "b#{$n += 1}") = [x, y]
  def after(x = "a#{$n += 1}", y = "b#{$n += 1}") = [x, y]
  def self.cm(x = "a#{$n += 1}", y = "b#{$n += 1}") = [x, y]
  def vecs(a = Vec.new($n += 1, 2), b = Vec.new($n += 1, 4)) = [a.x, a.y, b.x, b.y]
  def empty(x = ($n += 1), y = ($n += 1)) = [x, y]
  def given(a, x = ($n += 1), y = "b#{$n += 1}") = [a, x, y]
  def big(x = "a" * 3_000_000, y = ($n += 1)) = x.size + y
end

class Kid < Base
  def pos = super
  def ints = super
  def reads = super
  def mixed = super
  def keys(**o) = super
  def cond(f) = f && super
  def self.cm = super
  def vecs = super
  def rest(*a) = super
  def after = "#{bump} #{super}"
  def empty = super()
  def given(a) = super(a)

  def big
    n = super
    GC.start
    p((GC.stat["str_bytes"] || 0) < 2_000_000)
    n
  end
end

class Made
  attr_reader :v
  def initialize(x = "a#{$n += 1}", y = "b#{$n += 1}")
    @v = [x, y]
  end
end
class MadeKid < Made
  def initialize = super
end

k = Kid.new
p k.pos
p k.ints
p k.reads
p k.mixed
p k.keys
p k.keys(y: "given")
p k.rest
p k.rest("given")
p Kid.cm
p MadeKid.new.v
p k.after
p k.cond(false), $n
p k.cond(true), $n
p k.vecs
p k.empty
p k.given("g")
$n = 0
p k.big
