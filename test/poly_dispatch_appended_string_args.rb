# Two String arguments a method appends to, through a dispatch on a
# receiver of several classes: each goes over as a fresh handle on the
# caller's String, and bare in the arm's call the second handle's
# allocation collected the first. gc-stress-test runs this under
# SPINEL_GC_STRESS=2.
class Img
  def both(s, t)
    s << "x"
    t << "y"
    [s, t]
  end

  def three(s, t, u)
    s << "1"
    t << "2"
    u << "3"
    [s, t, u]
  end

  def with_default(s, x = "a" * 2)
    s << "x"
    [s, x]
  end
end

class Other
  def both(s, t) = 0
  def three(s, t, u) = 0
  def with_default(s) = 0
end

y = [Img.new, Other.new][0]
p y.both(+"a", +"b")
u = +"c"
v = +"d"
p y.both(u, v), u, v
p y.both("e" * 2, "f" * 2)
p y.three(+"a", +"b", +"c")
p y.with_default(+"s"), y.with_default(+"s", "t")
w = Img.new
p w.both(+"a", +"b"), w.three(+"a", +"b", +"c")
