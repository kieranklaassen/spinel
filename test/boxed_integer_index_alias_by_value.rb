# A method can be given under a name the text does not spell: here
# `alias_method` takes its name by value and gives Integer a `[]` of its
# own, which no node shows. Bit 0, which a boxed Integer answered an index
# that is no Integer, is that method's answer: in a program that names a
# method by value, every read keeps the answer it gave.
class Integer
  def one(k) = 1
  alias_method "[]".to_sym, :one
end
a = [5, Rational(3, 2), "s"]
x = a[0]
k = a[1]
p x[k]
