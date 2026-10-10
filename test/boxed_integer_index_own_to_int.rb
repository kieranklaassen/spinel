# CRuby's Integer#[] asks an index that is no Integer for `to_int`. Where
# the program gives Rational one of its own, the bit read is the one that
# method names: bit 0 here, which a boxed Integer answered. In a program
# with a def or a Symbol named `to_int`, every read keeps the answer it
# gave.
class Rational
  def to_int = 0
end
a = [5, Rational(3, 2), "s"]
x = a[0]
k = a[1]
p x[k]
