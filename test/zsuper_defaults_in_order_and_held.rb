# A bare `super` leaves the parent's optional parameters to their defaults.
# They were written side by side in the call's parentheses, where C runs them
# in any order (gcc: the last first), and where the one made first was
# collected while the next was made.

$n = 0
def bump = "u#{$n += 100}"

class Base
  def pos(x = "a#{$n += 1}", y = "b#{$n += 1}", z = "c#{$n += 1}") = [x, y, z]
  def ints(x = ($n += 1), y = ($n += 1), z = ($n += 1)) = [x, y, z]
  def mixed(x = "a#{$n}", y = ($n += 1), z = "c#{$n}") = [x, y, z]
  def keys(x: "a#{$n += 1}", y: "b#{$n += 1}", z: "c#{$n += 1}") = [x, y, z]
  def cond(f, x = "a#{$n += 1}", y = "b#{$n += 1}") = [x, y]
  def rest(x = "a#{$n += 1}", y = "b#{$n += 1}") = [x, y]
  def after(x = "a#{$n += 1}", y = "b#{$n += 1}") = [x, y]
  def self.cm(x = "a#{$n += 1}", y = "b#{$n += 1}") = [x, y]
  def two(x = "a" * 2, y = "c" * 2) = [x, y]
  def interp(x = "v#{$n}", y = "w#{$n}") = [x, y]
  def objs(x = Base.new, y = [1, 2].map { |e| e + 1 }, z = "s" * 3) = [x.class, y, z]
  def count = ("z" * 40).size + [1, 2, 3].sum
  def scalar(x = count, y = "c" * 2) = [x, y]
  def one_key(x: "a" * 2, y: 7) = [x, y]
end

class Kid < Base
  def pos = super
  def ints = super
  def mixed = super
  def keys(**o) = super
  def cond(f) = f && super
  def self.cm = super
  def two = super
  def interp = super
  def objs = super
  def scalar = super
  def one_key(**o) = super
  def rest(*a) = super
  def after = "#{bump} #{super}"
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

# the order
p k.pos
p k.ints
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

# the values, kept and read back
bad = 0
keep = []
300.times do |i|
  $n = i
  a = k.two
  b = k.interp
  c = k.objs
  d = k.scalar
  e = k.one_key
  keep << a << b << c << d << e
  bad += 1 unless a == ["aa", "cc"] && b == ["v#{i}", "w#{i}"] && c == [Base, [2, 3], "sss"]
  bad += 1 unless d == [46, "cc"] && e == ["aa", 7]
end
late = 0
keep.each_slice(5).with_index do |(a, b, c, d, e), i|
  late += 1 unless a == ["aa", "cc"] && b == ["v#{i}", "w#{i}"] && c == [Base, [2, 3], "sss"]
  late += 1 unless d == [46, "cc"] && e == ["aa", 7]
end
p bad, late, keep.size
