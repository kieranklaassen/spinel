# An arm under a test the compiler decides for its own engine is dropped
# before anything in it is compiled, and CRuby runs it: here it gives
# Integer a `[]` of its own. Bit 0, which a boxed Integer answered an index
# that is no Integer, is that method's answer: in such a program every read
# keeps the answer it gave.
if RUBY_ENGINE == "ruby"
  class Integer
    def [](k) = 1
  end
end
a = [5, Rational(3, 2), "s"]
x = a[0]
k = a[1]
p x[k]
