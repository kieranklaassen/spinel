# Two omitted parameters whose values each build an object, through a
# dispatch on a receiver of several classes: a default that allocates
# beside another one, beside an omitted *rest, beside a **kwrest. Bare in
# the arm's call, the second one's allocation collected the first.
# gc-stress-test runs this under SPINEL_GC_STRESS=2.
class Img
  def initialize = @d = "dd"
  def two(x = "a" * 2, y = "c" * 2) = [x, y]
  def three(a, x = "a" * 2, y = "c" * 2) = [a, x, y]
  def opt_rest(x = "a" * 2, *r) = [x, r]
  def opt_kwrest(x = "a" * 2, **o) = [x, o.size]
  def hash_rest(x = {}, *r) = [x, r]
  def array_hash(x = [], h = {}) = [x, h]
  def keys(k: "a" * 2, j: "c" * 2) = [k, j]
  def rest_key(*r, k: "a" * 2) = [r, k]
  def key_kwrest(k: "a" * 2, **o) = [k, o.size]
  def ivars(x = @d * 2, y = @d + "z") = [x, y]
  def objects(x = Other.new, y = Other.new) = [x.class, y.class]
  def sum_rest(x = [1, 2].map { _1 + 1 }.sum, *r) = [x, r]
end

class Other
  def two = 0
  def three(a) = 0
  def opt_rest = 0
  def opt_kwrest(**o) = 0
  def hash_rest = 0
  def array_hash = 0
  def keys(**o) = 0
  def rest_key(*r) = 0
  def key_kwrest(**o) = 0
  def ivars = 0
  def objects = 0
  def sum_rest = 0
end

y = [Img.new, Other.new][0]
# nothing passed: every parameter takes its default
p y.two, y.opt_rest, y.opt_kwrest
p y.hash_rest, y.array_hash
p y.keys, y.rest_key, y.key_kwrest
p y.ivars, y.objects, y.sum_rest
# some passed: the others still take theirs
p y.three(1), y.two("x"), y.opt_kwrest(q: 3), y.two("x", "y")
p y.rest_key(1, 2), y.keys(j: "j"), y.key_kwrest(q: 3), y.opt_rest("x", 1)
# a call that only spreads: each parameter is read out of what the spread
# brought, or takes its default
e = []
one = [1]
h = {}
p y.two(*e), y.three(*one), y.opt_rest(*e), y.two(**h), y.keys(**h)
# the other class's arm, and a receiver of one class
z = [Img.new, Other.new][1]
p z.two, z.three(1), z.keys
w = Img.new
p w.two, w.opt_rest, w.rest_key, w.objects
