# A `when` arm that makes its object is the receiver of the class's own ==
# or ===. The call was handed the fresh object directly, in no root: the
# method collected, the arm was freed, and the next object of that size took
# its place, so `self` read another object's fields.

# One allocation past the collection threshold, then objects of the arm's
# own size to take the place it was freed from.
def churn(kind)
  $pad = "x" * 4_000_000
  junk = []
  64.times { |i| junk << (kind == :pt ? Pt.new(i + 100) : Near.new(i + 100)) }
  junk.size
end

class Pt
  attr_accessor :v
  def initialize(v); @v = v; end
  def ===(o)
    churn(:pt)
    v == o.v
  end
end

class Near
  attr_accessor :v
  def initialize(v); @v = v; end
  def ===(o)
    churn(:near)
    v == o.v
  end
end

class Eq
  attr_accessor :v
  def initialize(v); @v = v; end
  def ==(o)
    $pad = "x" * 4_000_000
    junk = []
    64.times { |i| junk << Eq.new(i + 100) }
    v == o.v
  end
end

# the calls that give each method's parameter its type
p(Pt.new(1) === Pt.new(2))
p(Near.new(1) === Pt.new(2))
p(Eq.new(1) == Eq.new(2))

# the class's own ===, statement and value
case Pt.new(3)
when Pt.new(3) then puts "stmt: same"
else puts "stmt: other"
end
p(case Pt.new(3) when Pt.new(3) then :same else :other end)

# a later arm, and a later value of one arm
case Pt.new(3)
when Pt.new(4) then puts "second: four"
when Pt.new(3) then puts "second: same"
else puts "second: other"
end
case Pt.new(3)
when Pt.new(4), Pt.new(3) then puts "list: same"
else puts "list: other"
end

# another class's === taking the subject
case Pt.new(3)
when Near.new(3) then puts "near: same"
else puts "near: other"
end

# == alone
case Eq.new(3)
when Eq.new(3) then puts "eq: same"
else puts "eq: other"
end
p(case Eq.new(3) when Eq.new(3) then :same else :other end)

# in a method, the arm made by a call
def make(v) = Pt.new(v)
def pick(s)
  case s
  when make(3) then "def: same"
  else "def: other"
  end
end
puts pick(Pt.new(3))

# an arm that is a local is held by the local, as before
held = Pt.new(3)
case Pt.new(3)
when held then puts "local: same"
else puts "local: other"
end
