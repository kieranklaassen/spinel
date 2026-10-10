# A file the compiler does not read (its name is computed) can give a class
# a `[]` or an operator of its own, and CRuby calls it. Bit 0, which a boxed
# Integer answered an index that is no Integer, is that method's answer
# here: in such a program every read keeps the answer it gave.
begin
  require "#{__dir__}/boxed_integer_index_unread_file/plus"
rescue LoadError
end
a = [5, Rational(3, 2), "s"]
$x = a[0]
r = a[1]
p $x[r + 0]
begin
  require "#{__dir__}/boxed_integer_index_unread_file/index"
rescue LoadError
end
x = a[0]
k = a[1]
p x[k]
