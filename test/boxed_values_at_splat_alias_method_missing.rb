# A splat asks to_a of what has none through method_missing, and an alias
# can give a class one with no def of that name. Where the program names
# method_missing at all, a splat in values_at on a boxed receiver is read
# as it was.

class Integer
  def mm(n, *args)
    []
  end
  alias method_missing mm
end
a = [[10, 20, 30], nil][ARGV.size]
i = ARGV.size + 1
p a.values_at(0, *i)
