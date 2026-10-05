# `total += v` into an Integer local with a boxed operand of a builtin class
# that is no number, in a program that gives such a class a coerce of its
# own. The Integer slot converts the operand (true as 1, a String as the
# number it starts with), which is what these methods answer; a boxed `+`
# does not ask the program's coerce. Such a program keeps the Integer slot.
class TrueClass
  def coerce(n) = [n, 1]
end
class String
  def coerce(n) = [n, to_i]
end

row = [3, true, 4]
total = 0
row.each { |v| total += v }
p total
prod = 1
row.each { |v| prod *= v }
p prod

words = [3, "12 apples", 4]
sum = 0
words.each { |v| sum += v }
p sum
