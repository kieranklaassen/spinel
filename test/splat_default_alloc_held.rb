# A parameter a spread does not reach takes its default, written where the
# argument stands in the call: (0 < len ? elem : default). A default that
# allocates is then fresh inside the call's parentheses, where the next
# argument's allocation, or the callee's own, collects it.
class Other
end
def two(x = "a" * 2, y = "c" * 2) = [x, y]
def lead(a, x = "a" * 2, y = [a]) = [a, x, y]
def keys(k: "a" * 2, j: "c" * 2) = [k, j]
def objs(x = Other.new, y = Other.new) = [x.class, y.class]
class Img
  def initialize(x = "a" * 2, y = "c" * 2)
    @v = [x, y]
  end
  def v = @v
  def self.two(x = "a" * 2, y = "c" * 2) = [x, y]
end
class Base
  def two(x = "a" * 2, y = "c" * 2) = [x, y]
end
class Kid < Base
  def two(*a) = super(*a)
end

e = []
one = ["p"]
h0 = {}
hk = { k: "kk" }
p two(*e), two(*one)
p lead(1, *e), lead(*one)
p keys(**h0), keys(**hk)
p objs(*e)
p Img.new(*e).v, Img.new(*one).v, Img.new(**h0).v
p Img.two(*e)
p Kid.new.two, Kid.new.two("q")

bad = 0
kept = []
i = 0
while i < 200
  v = two(*e)
  kept << v
  bad += 1 unless v == ["aa", "cc"]
  i += 1
end
kept.each { |w| bad += 1 unless w == ["aa", "cc"] }
p bad
