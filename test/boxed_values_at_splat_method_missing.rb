# A splat asks to_a of what has none through method_missing. Where the
# program has a method_missing of its own, a splat in values_at on a boxed
# receiver is read as it was.

class Integer
  def method_missing(n, *args) = []
end
a = [[10, 20, 30], nil][ARGV.size]
i = ARGV.size + 1
p a.values_at(0, *i)
