# `case x in Klass` asks a class that defines === itself, as `when Klass` and
# `Klass === x` written out do: Module#=== (is_a?) is only the default.

class Even
  def self.===(o) = o.is_a?(Integer) && o.even?
end
class Plain; end
def kind(x)
  case x
  in Even then :even
  in Plain then :plain
  else :other
  end
end
p kind(4)
p kind(3)
p kind("s")
p kind(nil)
p kind(Even.new)
p kind(Plain.new)
r = case 8
    in Even => n then n + 1
    else 0
    end
p r
p((4 in Even))
p((3 in Even))
x = [4, 3]
case x
in [Even, Even] then puts "both"
in [Even, _] then puts "first"
else puts "none"
end
case {k: 6}
in {k: Even => v} then puts "k even #{v}"
else puts "no"
end
case 4
in Even | Plain then puts "alt"
else puts "no alt"
end
class Pt
  attr_reader :x
  def initialize(x) = @x = x
  def deconstruct_keys(_) = {x: @x}
  def self.===(o) = o.is_a?(Pt) && o.x > 0
end
case Pt.new(3)
in Pt(x:) then puts "pt #{x}"
else puts "not pt"
end
case Pt.new(-3)
in Pt(x:) then puts "pt #{x}"
else puts "not pt"
end
s = 5 if ARGV.size == 0
case s
in Even then puts "s even"
in Integer then puts "s int"
else puts "s other"
end

# a captured value, a guard, an element, a Hash value, an alternative
class Any
  def self.===(o) = true
end
class Thing
  attr_reader :v
  def initialize(v) = @v = v
  def self.===(o) = o.is_a?(String) || o.is_a?(Thing)
end
def a(x)
  case x
  in Even => n then n + 1
  else 0
  end
end
p a(4), a(3), a("s")
def b(x)
  case x
  in Any => n then n.inspect
  end
end
p b(4), b("s"), b(nil), b([1, 2]), b(Any.new.class)
def d(x)
  case x
  in Thing => n then n.to_s.size > 0
  else :no
  end
end
p d("str"), d(Thing.new(2)), d(4)
def e(x)
  case x
  in Thing then x.is_a?(Thing) ? x.v : x
  else :no
  end
end
p e("str"), e(Thing.new(2)), e(4)
def f(x)
  case x
  in [Even => m, Any => n] then [m, n]
  in {k: Thing => t} then t.is_a?(String)
  in Even | Thing => q then q
  else :none
  end
end
p f([2, "z"]), f([3, 1]), f({k: "s"}), f({k: 1}), f(8), f("w"), f(7)
t = Thing.new(5)
case t
in Thing => n then p n.v
end
i = 6
case i
in Even => n then p n * 2
end
s = "str"
r = case s
    in Thing => n then n.upcase
    else "none"
    end
p r
def g(x)
  case x
  in Even if x > 10 then :big
  in Even then :small
  in ^x then :same
  end
end
p g(12), g(2), g(1)
p((Thing.new(1) in Thing), ("s" in Thing), (1 in Thing), (2 in Even => z), z)
