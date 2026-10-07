# A `when` arm whose === or == is inherited: the typed function takes the
# class that defines the method, and the arm was passed as its own class,
# which did not compile.
class Base
  attr_reader :v
  def initialize(v) = @v = v
  def ===(o) = v == o.v
end
class P < Base; end
p(P.new(8) === P.new(9))

case P.new(1)
when P.new(1) then puts "same"
else puts "other"
end
case P.new(1)
when P.new(2) then puts "same"
else puts "other"
end
p(case P.new(1) when P.new(1) then :same else :other end)
p(case P.new(1) when P.new(2) then :same else :other end)
held = P.new(3)
p(case P.new(3) when P.new(2), held then :same else :other end)

def pick(a, b)
  case a
  when b then :same
  else :other
  end
end
p pick(P.new(4), P.new(4))
p pick(P.new(4), P.new(5))

# == alone, inherited: the same object matches without a call
$calls = 0
class EBase
  attr_reader :v
  def initialize(v) = @v = v
  def ==(o) = ($calls += 1; v == o.v)
end
class E < EBase; end
p(E.new(8) == E.new(9))
e1 = E.new(1)
case e1
when E.new(1) then puts "same"
else puts "other"
end
case e1
when e1 then puts "same"
else puts "other"
end
p $calls
p(case e1 when E.new(1) then :same else :other end)
p(case e1 when E.new(2) then :same else :other end)

# two levels up
class Mid < Base; end
class Leaf < Mid; end
p(Leaf.new(8) === Leaf.new(9))
case Leaf.new(6)
when Leaf.new(6) then puts "same"
else puts "other"
end

# the arm of another class than the subject
class Above
  def initialize(n) = @n = n
  def lift = @n += 1
  def ===(o) = o > @n
end
class Far < Above; end
far = Far.new(10)
far.lift
p(far === 2)
case 12
when far then puts "hit"
else puts "miss"
end
case 11
when far then puts "hit"
else puts "miss"
end
