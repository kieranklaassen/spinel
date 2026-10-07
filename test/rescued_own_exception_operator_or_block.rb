# An exception class with an operator of its own, or a method that yields:
# called through a boxed value neither has an arm for a boxed exception, so
# the class test is left as it was and the branch is not reached.
class Scored < StandardError
  def +(o) = "plus#{o}"
end
class Parted < StandardError
  def parts
    yield 1
    yield 2
  end
end
class Deeper < Parted; end

kept = [3]
begin; raise Scored, "s"; rescue StandardError => e; kept << e; end
begin; raise Deeper, "d"; rescue StandardError => e; kept << e; end
total = 0
kept.each do |v|
  v + 1 if v.is_a?(Scored)
  v.parts { |q| total += 0 } if v.is_a?(Parted)
end
p total
puts "end"
