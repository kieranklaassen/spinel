# A `when` arm that a call makes is the receiver of its own == or ===. The
# method may collect, so the arm is held in a root while it runs. Each ==
# below makes garbage before it reads its own fields.

def churn
  i = 0
  while i < 20000
    [Level.new(i + 100)]
    {a: Span.new(i + 100)}
    i += 1
  end
end

class Level
  attr_reader :n
  def initialize(n) = @n = n
  def ==(o)
    churn
    o > @n
  end
end

class Span
  attr_reader :n
  def initialize(n) = @n = n
  def ==(o)
    churn
    o.size > @n
  end
end

def level(i) = Level.new(i)
def levels(i) = [Level.new(i)]
def level_map(i) = {a: Level.new(i)}
def span(i) = Span.new(i)

# an Array or a Hash that a call made, beside an Array or Hash subject
a = [5]
p(case a when levels(8) then :hit else :miss end)
p(case a when levels(1) then :hit else :miss end)
case a
when levels(1) then puts "hit"
else puts "miss"
end
h = {a: 5}
p(case h when level_map(8) then :hit else :miss end)
p(case h when level_map(1) then :hit else :miss end)

# an object arm beside an Array subject
list = [1, 2, 3]
p(case list when span(8) then :hit else :miss end)
p(case list when span(1) then :hit else :miss end)
case list
when span(1) then puts "hit"
else puts "miss"
end

# an object arm beside an Integer subject, in a case used as a value
s = 5
p(case s when level(8) then :hit else :miss end)
p(case s when level(1) then :hit else :miss end)
p(case s when Level.new(8) then :hit else :miss end)
p(case s when Level.new(1) then :hit else :miss end)

# a Struct arm, whose == asks its members
Pair = Struct.new(:a)
def pair(i) = Pair.new(Level.new(i))
q = Pair.new(5)
p(case q when pair(8) then :hit else :miss end)
p(case q when pair(1) then :hit else :miss end)

# an arm of a class with no == of its own: identity, nothing to root
class Plain; end
def plain = Plain.new
p(case s when plain then :hit else :miss end)

# arms that hold their value already: a literal, an element read
ls = [Level.new(8), Level.new(1)]
p(case a when [Level.new(8)] then :hit else :miss end)
p(case a when [Level.new(1)] then :hit else :miss end)
p(case s when ls[0] then :hit else :miss end)
p(case s when ls[1] then :hit else :miss end)
p(case [1, 2] when [1, 2].map { |x| x } then :hit else :miss end)
