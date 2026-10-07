# `case v when obj` is `obj === v`. Where a call written out had typed the
# parameter of the arm's own === and the case subject is held boxed, the
# subject was compared with the arm as a value and the === never called.
class Above
  attr_accessor :n
  def initialize(n) = @n = n
  def ===(o) = o.is_a?(Integer) && o > @n
end
big = Above.new(3)
p(big === 1)
row = [1, 5, "x", :s, nil, 2.5]
row.each do |x|
  case x
  when big then puts "big"
  else puts "other"
  end
end
p(row.map { |x| case x when big then 1 else 0 end })

# a parameter typed a Float, a Symbol, a String
class Near
  attr_accessor :v, :c
  def initialize(v) = @v = v
  def ===(o) = o.is_a?(Float) && (o - @v).abs < 1.0
end
near = Near.new(2.0)
p(near === 9.5)
p([2.5, 7.5, 2, "s"].map { |x| case x when near then 1 else 0 end })

class Starts
  attr_accessor :v, :c
  def initialize(c) = @c = c
  def ===(o) = o.is_a?(Symbol) && o.to_s.start_with?(@c)
end
st = Starts.new("a")
p(st === :pear)
p([:apple, :fig, "avocado", 3].map { |x| case x when st then 1 else 0 end })

class Pre
  attr_accessor :v, :c
  def initialize(c) = @c = c
  def ===(o) = o.is_a?(String) && o.start_with?(@c)
end
pre = Pre.new("a")
p(pre === "pear")
p(["apple", "fig", :avocado, 3].map { |x| case x when pre then 1 else 0 end })

# an object parameter, the subject read out of a mixed Array
class Pt
  attr_accessor :v
  def initialize(v) = @v = v
end
class Close
  attr_accessor :v, :c
  def initialize(v) = @v = v
  def ===(o) = o.is_a?(Pt) && (o.v - @v).abs < 2
end
close = Close.new(10)
p(close === Pt.new(3))
[Pt.new(9), 5, Pt.new(20)].each do |q|
  case q
  when close then puts "close"
  else puts "far"
  end
end

# the call written out is what it was
p(big === 9)
p(near === 2.25)

# a local as the argument of the typing call
t = 4
p(big === t)
p([8, :s].map { |x| case x when big then 1 else 0 end })
