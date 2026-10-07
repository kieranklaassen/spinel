# A boxed div, divmod, remainder or fdiv beside an operand of a builtin class
# that is no number, in a program that gives such a class a coerce of its
# own. The boxed helpers do not ask the program's coerce: they convert the
# operand (true as 1, nil as 0, a String by Float()), which is what these
# methods answer. The check that raises for such an operand leaves the
# program as it is.
class TrueClass
  def coerce(n) = [n, 1]
end
class String
  def coerce(n) = [n, to_f]
end
class NilClass
  def coerce(n) = [n, 0]
  def div(o) = 0
  def divmod(o) = [0, 0]
end

row = [7, true, "2", nil]
p row[0].divmod(row[1])
p row[0].div(row[1])
p row[0].remainder(row[1])
p row[0].fdiv(row[2])
begin
  p row[0].div(row[3])
rescue ZeroDivisionError => e
  puts e.message
end

# a named call on the reopened class goes to the program's method
p row[3].div(2)
p row[3].divmod(2)
