# CRuby's Integer#[] asks an index that is no Integer by rb_check_funcall,
# which first calls a `respond_to?` the program gave. One that answers
# false for a Rational makes the read a TypeError, and the rescue here
# prints what bit 0, which a boxed Integer answered, printed. In a program
# with a def or a Symbol named `respond_to?`, every read keeps the answer
# it gave.
class Rational
  def respond_to?(m, p = false) = false
end
a = [6, Rational(3, 2), "s"]
x = a[0]
k = a[1]
begin
  p x[k]
rescue TypeError
  p 0
end
