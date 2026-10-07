# A `when` arm that is nil when the case runs is not asked its ===: nil
# matches a nil subject alone. The case statement, and both forms beside an
# Array or Hash subject, called the arm's method on nil.
class Above
  attr_accessor :n
  def initialize(n) = @n = n
  def ===(o) = o > @n
end
def above(i) = i > 0 ? Above.new(i) : nil
p(Above.new(1) === 2)
[0, 3, 9].each do |i|
  case 5
  when above(i) then puts "hit"
  else puts "miss"
  end
end

# an Array subject, both forms
class Longer
  attr_accessor :n
  def initialize(n) = @n = n
  def ===(o) = o.size > @n
end
def longer(i) = i > 0 ? Longer.new(i) : nil
p(Longer.new(1) === [1, 2])
s = [1, 2, 3]
p([0, 2, 5].map { |i| case s when longer(i) then :hit else :miss end })
[0, 2].each do |i|
  case s
  when longer(i) then puts "hit"
  else puts "miss"
  end
end

# a Hash subject, the parameter typed by no call
class Wide
  attr_accessor :n
  def initialize(n) = @n = n
  def ===(o) = o.size > @n
end
def wide(i) = i > 0 ? Wide.new(i) : nil
h = { a: 1, b: 2 }
p([0, 1, 4].map { |i| case h when wide(i) then :hit else :miss end })

# an arm out of an instance variable, a local set on one path, a conditional
class Holder
  attr_accessor :arm
  def initialize = @arm = nil
end
hold = Holder.new
case 5
when hold.arm then puts "hit"
else puts "miss"
end
hold.arm = Above.new(2)
case 5
when hold.arm then puts "hit"
else puts "miss"
end
a = nil
a = Above.new(7) if ARGV.size > 5
case 9
when a then puts "hit"
else puts "miss"
end
p(case s when (ARGV.size > 5 ? Longer.new(1) : nil) then :hit else :miss end)

# a nil arm beside a second arm, which is still asked
case 5
when above(0), above(2) then puts "hit"
else puts "miss"
end

# an object subject: a nil arm matches a nil subject and no other
class Box
  attr_accessor :n
  def initialize(n) = @n = n
end
class Over
  attr_accessor :n
  def initialize(n) = @n = n
  def ===(o) = o.n > @n
end
def over(i) = i > 0 ? Over.new(i) : nil
def box(i) = i > 0 ? Box.new(i) : nil
p(Over.new(1) === Box.new(2))
case box(0)
when over(0) then puts "hit"
else puts "miss"
end
case box(5)
when over(0) then puts "hit"
else puts "miss"
end
case box(5)
when over(3) then puts "hit"
else puts "miss"
end

# a subject of the arm's own class, with === and with == alone
class Lvl
  attr_accessor :n
  def initialize(n) = @n = n
  def ===(o) = o.n >= @n
end
def lvl(i) = i > 0 ? Lvl.new(i) : nil
p(Lvl.new(1) === Lvl.new(2))
case Lvl.new(5)
when lvl(0) then puts "hit"
when lvl(3) then puts "level 3"
else puts "miss"
end
p(case Lvl.new(2) when lvl(0) then :hit when lvl(3) then :l3 else :miss end)
case lvl(0)
when lvl(0) then puts "nil is nil"
else puts "miss"
end
class Tag
  attr_accessor :s
  def initialize(s) = @s = s
  def ==(o) = o.s == @s
end
def tag(s) = s ? Tag.new(s) : nil
case Tag.new("a")
when tag(nil) then puts "hit"
when tag("a") then puts "tag a"
else puts "miss"
end
p(case tag(nil) when tag(nil) then :both_nil else :miss end)
