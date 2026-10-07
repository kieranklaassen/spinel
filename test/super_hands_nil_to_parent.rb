# A number that can be nil is still nil once `super` has handed it to the
# parent method. Each parent method here gets its value only through a
# child's `super`, from one call a number and from another nil.
class Account
  attr_reader :rate
  def initialize(rate)
    @rate = rate
  end
  def summary = ["rate", @rate]
end
class Savings < Account
  def initialize(rate) = super
end
p Savings.new(1.5).summary
p Savings.new(nil).summary

class Shape
  def scaled(k) = { "k" => k, "n" => 1 }
  def each_factor(k)
    yield k
  end
  def named(k:, unit: 1) = [k, unit]
  def second(a, k) = [a, k]
end
class Square < Shape
  def scaled(k) = super(k)
  def each_factor(k, &b) = super(k, &b)
  def named(unit: 1, k:) = super
  def second(a, k) = super
end
sq = Square.new
p sq.scaled(2.5)["k"], sq.scaled(nil)["k"]
sq.each_factor(2.5) { |f| p f.nil? }
sq.each_factor(nil) { |f| p f.nil?, (f || 1.0) }
p sq.named(k: nil), sq.named(k: 0.5, unit: 2)
p sq.second("a", nil), sq.second("b", 3.5)

# a module's method between the two, and a chain of two supers where the
# value is nil only some of the time
module Pass
  def go(x)
    super
  end
end
class Low
  def go(x)
    yield(x)
  end
end
class Mid < Low
  def go(x)
    super(x > 1 ? x : nil)
  end
end
class Top < Mid
  include Pass
end
p Top.new.go(0.5) { |v| [v] }
p Top.new.go(2.5) { |v| [v] }

# an Integer read from an instance variable that nothing may have set
class Gauge
  def read(n)
    yield n
  end
end
class Meter < Gauge
  def initialize(set)
    @n = 5 if set
  end
  def read(&b) = super(@n, &b)
end
Meter.new(true).read { |v| p v.nil?, v.inspect }
Meter.new(false).read { |v| p v.nil?, v.inspect }
