# An arm under a test the compiler decides for its own engine is dropped
# before anything in it is compiled, and CRuby runs it: here it gives
# Integer and Range a to_a of their own. In such a program a splat in
# values_at on a boxed receiver is read as it was: none.
if RUBY_ENGINE == "ruby"
  class Integer
    def to_a = []
  end
  class Range
    def to_a = []
  end
end
a = [[10, 20, 30], nil][ARGV.size]
i = 2
p a.values_at(*i)
p a.values_at(*(0..1))
