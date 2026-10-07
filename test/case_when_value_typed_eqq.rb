# A case used as a value asks an object arm its ===, as a case statement
# does, when the method takes the subject's own type: the arm was compared
# as a pointer and the else arm taken.
class Above
  def initialize(n) = @n = n
  def ===(o) = o > @n
end
above = Above.new(3)
p(above === 1)

p(case 5 when above then :hit else :miss end)
p(case 2 when above then :hit else :miss end)
x = case 9 when Above.new(10) then "ten" when Above.new(8) then "eight" else "none" end
puts x
y = case 9 when Above.new(10), above then "listed" else "none" end
puts y

def band(n, lo, hi)
  case n
  when hi then :high
  when lo then :mid
  else :low
  end
end
p band(9, Above.new(2), Above.new(6))
p band(5, Above.new(2), Above.new(6))
p band(1, Above.new(2), Above.new(6))

# an arm of another class beside an object subject
class Pt
  attr_reader :v
  def initialize(v) = @v = v
end
class Near
  attr_accessor :v
  def initialize(v) = @v = v
  def ===(o) = (o.v - @v).abs < 2
end
p(Near.new(3) === Pt.new(9))
p(case Pt.new(4) when Near.new(3) then :near else :far end)
p(case Pt.new(7) when Near.new(3) then :near else :far end)
near = Near.new(10)
def tag(pt, near) = case pt when near then 1 else 0 end
p [tag(Pt.new(9), near), tag(Pt.new(20), near)]

# the statement, which already asked
case 5
when above then puts "hit"
else puts "miss"
end

# an inherited ===
class Wide < Above; end
p(case 5 when Wide.new(4) then :hit else :miss end)
p(case 4 when Wide.new(4) then :hit else :miss end)
