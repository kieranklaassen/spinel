# A boxed `/` or `%` beside a value of a builtin class that is no number, in
# a program that gives such a class a division or a coerce of its own. The
# boxed operator does not reach the program's method: it converts the value
# (nil as 0, true as 1, a String as the number it starts with), which is
# what these methods answer. The check that raises for a value that is no
# number leaves such a program as it is.
class NilClass
  def /(o) = 0
  def coerce(n) = [n, 0]
end
class String
  def /(o) = to_i / o
  def coerce(n) = [n, to_i]
end
class Symbol
  def /(o) = 0
end
class TrueClass
  def coerce(n) = [n, 1]
end

def avg(row) = row[0] / row[1]
def rem(row) = row[0] % row[1]

# the receiver's own operator
p avg([nil, 2])
p avg([9, 2])
p avg([9.0, 2])
p avg(["12 apples", 4])
p avg([:a, 1000, :b])
p nil / 2
p "12 apples" / 4

# the operand's coerce
p avg([7, true])
p rem([7, true])
p avg([12, "4 apples"])
p rem([13, "4 apples"])
begin
  p avg([7, nil])
rescue ZeroDivisionError => e
  puts e.message
end
