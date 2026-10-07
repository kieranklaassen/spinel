# `case v when obj` is `obj === v`: the arm's own === takes the case subject
# as its argument. A call written out had typed the parameter, and a subject
# of another kind was then compared with the arm as a value and never passed.
class Above
  attr_accessor :n
  def initialize(n) = @n = n
  def ===(o) = o > @n
end
big = Above.new(3)
p(big === 1)
row = [1, 5, 2.5, 7.25]
row.each do |x|
  case x
  when big then puts "big"
  else puts "other"
  end
end
p(row.map { |x| case x when big then 1 else 0 end })

# a Float subject beside a parameter an Integer call typed
p(case 3.5 when big then :big else :other end)
case 3.5
when big then puts "big"
else puts "other"
end

# an object parameter, a boxed subject
class Pt
  attr_accessor :v
  def initialize(v) = @v = v
end
class Near
  attr_accessor :v
  def initialize(v) = @v = v
  def ===(o) = (o.v - @v).abs < 2
end
near = Near.new(10)
p(near === Pt.new(3))
pts = [Pt.new(9), Pt.new(20)]
pts.each do |pt|
  case pt
  when near then puts "near"
  else puts "far"
  end
end
p(pts.map { |pt| case pt when near then 1 else 0 end })

# == alone, which Object#=== calls
class Tag
  attr_accessor :s
  def initialize(s) = @s = s
  def ==(o) = o.to_s == @s
end
t = Tag.new("7")
p(t == "7")
p([7, "7", :x].map { |x| case x when t then 1 else 0 end })

# a subject the method cannot take raises, as the call written out does
begin
  [2, "x"].each { |x| case x when big then puts "big" else puts "other" end }
rescue ArgumentError
  puts "ArgumentError"
end

# the parameter boxed by a case of another kind still answers the call
# written out by what it holds
class Same
  attr_accessor :id
  def initialize(v) = @id = v.object_id
  def ===(o) = o.object_id == @id
end
same = Same.new(5)
p(same === 5)
case :sym
when same then puts "same"
else puts "other"
end
