# A `when` arm of a small read-only class (one kept by value) is asked its
# own ===: it was boxed and compared as a value, and the else arm taken.
class Above
  def initialize(n) = @n = n
  def ===(o) = o > @n
end
case 5
when Above.new(3) then puts "big"
else puts "other"
end
p(case 5 when Above.new(3) then :big else :other end)
p(case 2 when Above.new(3) then :big else :other end)
big = Above.new(3)
x = case 9 when Above.new(10) then "ten" when big then "three" else "none" end
puts x

# a boxed subject
class Even
  def initialize(k) = @k = k
  def ===(o) = o.is_a?(Integer) && o % @k == 0
end
row = [4, 7, "x", nil]
i = 0
while i < row.size
  case row[i]
  when Even.new(2) then puts "even"
  else puts "odd"
  end
  i += 1
end

# an answer that is no boolean
class Pos
  def initialize(a, b) = (@a = a; @b = b)
  def ===(o) = (o == @a ? 0 : (o == @b ? 1 : nil))
end
p(case 3 when Pos.new(3, 4) then :in else :out end)
p(case 5 when Pos.new(3, 4) then :in else :out end)

# == alone, which Object#=== calls
class Cents
  def initialize(c) = @c = c
  def ==(o) = o == @c
end
p(case 250 when Cents.new(250) then :same else :other end)
p(case 251 when Cents.new(250) then :same else :other end)

# a String field, the arm read from a local
class Len
  def initialize(s) = @s = s
  def ===(o) = @s.size == o
end
ln = Len.new("abc")
p(case 3 when ln then :len else :other end)
p(case 4 when ln then :len else :other end)
